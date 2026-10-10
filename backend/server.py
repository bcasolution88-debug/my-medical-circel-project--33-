#!/usr/bin/env python3
"""
Health Circle backend — REST API (Python stdlib + SQLite, zero dependencies).

Endpoints (JSON, CORS enabled):
  GET  /api/health
  POST /api/auth/send-code          {email}
  POST /api/auth/register           {email, code, password, name?}
  POST /api/auth/login              {email, password}
  GET  /api/auth/me                 (Bearer token)
  GET  /api/geofence                -> {name, lat, lng, radius_m, blocked_message}
  POST /api/geofence/check          {lat, lng} -> {inside, distance_m, radius_m}
  GET  /api/home                    carousel + hotCircles + hotForums + topics + categories
  GET  /api/events                  list (approved)
  GET  /api/events/{id}             detail (+1 view)
  POST /api/events/{id}/join        toggle signup (auth)
  POST /api/events                  submit (auth, pending)
  GET  /api/posts?kind=circle|forum|video&limit=
  GET  /api/posts/{id}
  POST /api/posts                   (auth) -> pending
  POST /api/posts/{id}/like         (auth) toggle
  POST /api/posts/{id}/fav          (auth) toggle
  GET  /api/posts/{id}/comments
  POST /api/posts/{id}/comments     (auth) {text}
  GET  /api/messages/summary        (auth) unread counts
  GET  /api/messages/{channel}      (auth) channel: service|feedback|sysnotify|share|user:{id}
  POST /api/messages/{channel}      (auth) {text}
  POST /api/feedback                (auth) {text}
  POST /api/upload                  raw image bytes -> {url}
  GET  /uploads/{name}
"""
import base64, hashlib, hmac, json, math, os, secrets, sqlite3, sys, time, uuid
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlparse, parse_qs

HERE = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.environ.get('HC_DB', os.path.join(HERE, 'health_circle.db'))
UPLOAD_DIR = os.path.join(HERE, 'uploads')
SECRET = os.environ.get('HC_SECRET', 'health-circle-dev-secret')
PORT = int(os.environ.get('PORT', '5061'))
os.makedirs(UPLOAD_DIR, exist_ok=True)

NOW = lambda: int(time.time() * 1000)


def db():
    c = sqlite3.connect(DB_PATH, check_same_thread=False)
    c.row_factory = sqlite3.Row
    return c


CONN = db()
LOCK = __import__('threading').Lock()


def q(sql, args=(), one=False, commit=False):
    with LOCK:
        cur = CONN.execute(sql, args)
        if commit:
            CONN.commit()
            return cur.lastrowid
        rows = cur.fetchall()
    if one:
        return dict(rows[0]) if rows else None
    return [dict(r) for r in rows]


# ───────────────────────── schema + seed ─────────────────────────
SCHEMA = """
CREATE TABLE IF NOT EXISTS users(id TEXT PRIMARY KEY, email TEXT UNIQUE, name TEXT, pwd TEXT, avatar TEXT,
  gender TEXT, seed TEXT, ip TEXT, created INTEGER);
CREATE TABLE IF NOT EXISTS codes(email TEXT PRIMARY KEY, code TEXT, ts INTEGER);
CREATE TABLE IF NOT EXISTS geofence(id INTEGER PRIMARY KEY CHECK(id=1), name TEXT, lat REAL, lng REAL, radius_m REAL, blocked TEXT);
CREATE TABLE IF NOT EXISTS events(id TEXT PRIMARY KEY, title TEXT, date TEXT, time TEXT, place TEXT, detail TEXT, seed TEXT,
  cover TEXT, views INTEGER, author TEXT, status TEXT, ts INTEGER);
CREATE TABLE IF NOT EXISTS event_signups(event_id TEXT, user TEXT, ts INTEGER, PRIMARY KEY(event_id,user));
CREATE TABLE IF NOT EXISTS posts(id TEXT PRIMARY KEY, kind TEXT, author TEXT, author_seed TEXT, gender TEXT, ts INTEGER,
  location TEXT, text TEXT, images TEXT, video TEXT, poll TEXT, circle_name TEXT, circle_seed TEXT, circle_sub TEXT,
  topic TEXT, views INTEGER, status TEXT, recommended INTEGER);
CREATE TABLE IF NOT EXISTS post_likes(post_id TEXT, user TEXT, PRIMARY KEY(post_id,user));
CREATE TABLE IF NOT EXISTS post_favs(post_id TEXT, user TEXT, PRIMARY KEY(post_id,user));
CREATE TABLE IF NOT EXISTS comments(id TEXT PRIMARY KEY, post_id TEXT, author TEXT, author_seed TEXT, text TEXT, ts INTEGER);
CREATE TABLE IF NOT EXISTS messages(id TEXT PRIMARY KEY, channel TEXT, owner TEXT, sender TEXT, text TEXT, ts INTEGER, read INTEGER);
CREATE TABLE IF NOT EXISTS feedback(id TEXT PRIMARY KEY, user TEXT, text TEXT, ts INTEGER);
CREATE TABLE IF NOT EXISTS home_cms(key TEXT PRIMARY KEY, value TEXT);
"""


def hash_pwd(p):
    return hashlib.sha256((SECRET + p).encode()).hexdigest()


def seed():
    for stmt in SCHEMA.strip().split(';'):
        if stmt.strip():
            q(stmt, commit=True)
    if q('SELECT 1 FROM users LIMIT 1'):
        return
    D = 86400000
    now = NOW()
    users = [
        ('u-me', 'me@healthcircle.app', '动感地带', 'Pass@2026', 'm', 'me', 'Shah Alam · Malaysia'),
        ('allanliu6', 'allan@example.com', 'allanliu6', 'Pass@2026', 'f', 'allanliu', '吉隆坡'),
        ('shier', 'shier@example.com', 'shier', 'Pass@2026', 'm', 'shier', '运城市'),
        ('mymuse60', 'muse@example.com', 'mymuse60', 'Pass@2026', 'f', 'muse', '槟城'),
        ('myunisocial', 'uni@example.com', 'myunisocial', 'Pass@2026', 'm', 'uni', '新山'),
        ('weichen', 'wei@example.com', 'weichen', 'Pass@2026', 'f', 'wei', '上海'),
        ('jacky', 'jacky@example.com', 'jacky', 'Pass@2026', 'm', 'jacky', '吉隆坡'),
        ('segi', 'segi@example.com', 'segi asia marketing (SAM)', 'Pass@2026', 'f', 'segi', '吉隆坡'),
        ('future', 'future@example.com', 'future', 'Pass@2026', 'm', 'future', '吉隆坡'),
        ('yy', 'yy@example.com', 'yy', 'Pass@2026', 'f', 'yy', '吉隆坡'),
        ('service', 'service@healthcircle.app', '健康圈子客服', 'Svc@2026', 'f', 'svc', '吉隆坡'),
    ]
    for uid, em, nm, pw, g, sd, ip in users:
        q('INSERT INTO users VALUES(?,?,?,?,?,?,?,?,?)', (uid, em, nm, hash_pwd(pw), '', g, sd, ip, now), commit=True)
    q('INSERT INTO geofence VALUES(1,?,?,?,?,?)',
      ('Kuala Lumpur · 吉隆坡', 3.1390, 101.6869, 2500000, '当前地区暂未开放注册与登录，请联系客服。'), commit=True)

    events = [
        ('uev-1', '健康读书会 · 十月共读《营养的真相》', '2026-10-20', '19:30', '社区健康服务中心', '每周一次线下共读，欢迎新朋友加入。', 'uev-1', '', 0, 'allanliu6', 'approved', now - 6 * D, []),
        ('ev1', '示例活动一 · 社区周末义诊', '2026-12-15', '19:00', '示例地点 · 由后台配置',
         '这里是活动详情示例。管理员在后台发布活动后，用户在此看到完整介绍、时间、地点与图片。', 'ev1', '/assets/images/home-info-1.jpg', 78, 'segi', 'approved', now - 10 * D,
         ['allanliu6', 'shier', 'mymuse60', 'myunisocial', 'weichen']),
        ('ev2', '示例活动二 · 高血压健康讲座', '2025-01-30', '09:00', '创新中心 3 楼', '48 小时团队协作挑战，欢迎所有感兴趣的朋友报名组队。', 'ev2', '/assets/images/home-info-2.jpg', 7, 'segi', 'approved', now - 12 * D, ['jacky']),
        ('ev3', '示例活动三 · 儿童疫苗咨询日', '2025-01-13', '14:30', '图书馆多功能厅', '分享你的健康经验和护理心得，现场有专业医师点评。', 'ev3', '', 3, 'segi', 'approved', now - 14 * D, ['future', 'yy', 'segi']),
        ('uev-2', '周末健步走活动', '2026-10-12', '10:00', '城市公园东门', '全程约 5 公里，有医护人员随行。', 'uev-2', '', 0, 'shier', 'pending', now - 3 * D, []),
    ]
    for e in events:
        q('INSERT INTO events VALUES(?,?,?,?,?,?,?,?,?,?,?,?)', e[:12], commit=True)
        for u in e[12]:
            q('INSERT INTO event_signups VALUES(?,?,?)', (e[0], u, now), commit=True)

    posts = [
        ('p1', 'circle', 'segi', 'f', now - 1 * D, '发布于吉隆坡', '秋季流感高发！本季第一个科普健康圈已经开放，欢迎大家一起交流防护心得，共同守护健康 🩺',
         ['f1a', 'f1b'], '', None, '健康知识分享', 'hc-res', '分享你的健康小妙招', '', 128, 1),
        ('p2', 'circle', 'segi', 'f', now - 2 * D, '发布于吉隆坡', 'AI 智能导诊 · 三甲医院线上问诊流程分享，从挂号到复诊的完整指南。',
         ['f2a', 'f2b', 'f2c', 'f2d', 'f2e'], 'sample', None, '宝妈育儿', 'hc-yy', '心情好，身体更健康', '', 342, 1),
        ('p3', 'circle', 'allanliu6', 'f', now - 3 * D, '发布于莎阿南', '今天分享一份控糖饮食计划表，希望对刚确诊的朋友有帮助。',
         ['f3a', 'f3b', 'f3c'], '', {'question': '你每年体检几次？', 'options': [
             {'text': '每年定期全面体检', 'votes': 6}, {'text': '只做基础项目体检', 'votes': 14}, {'text': '不舒服时再去看', 'votes': 9}]},
         '健康知识分享', 'hc-res', '分享你的健康小妙招', '', 96, 0),
        ('p4', 'circle', 'shier', 'm', now - 5 * D, '发布于运城市', '第一次体检，空腹与采血的一些小心得，希望对大家有用。', [], '', None,
         'CARE TOGETHER 互助', 'hc-team', '病友互助，一起加油', '', 41, 0),
        ('p5', 'circle', 'allanliu6', 'f', now - 7 * D, '发布于吉隆坡', '定期体检比生病后再治疗更划算，你们一年体检几次？', ['f5a', 'f5b', 'f5c', 'f5d'], 'sample', None,
         '中医养生馆', 'hc-car', '四季养生、食疗调理，一起交流经验', '', 77, 0),
        ('f1', 'forum', 'weichen', 'f', now - 1 * D, '发布于上海', '体检报告上的几个指标看不懂，有懂的朋友帮忙看看吗？', ['g1a'], '', None, '', '', '', '第一次体检，需要注意什么', 58, 0),
        ('f2', 'forum', 'jacky', 'm', now - 2 * D, '发布于吉隆坡', '康复训练第 30 天打卡，血压稳定了不少，分享一下我的计划。', ['g2a', 'g2b'], '', None, '', '', '', '高血压日常用药经验', 73, 1),
        ('f3', 'forum', 'mymuse60', 'f', now - 4 * D, '发布于槟城', '寻找一起健步走打卡的伙伴，每天早上 7 点～', [], '', None, '', '', '', '如何养成规律作息提升免疫力', 29, 0),
        ('v1', 'video', 'segi', 'f', now - 1 * D, '发布于吉隆坡', '3 分钟学会正确洗手 — 七步洗手法演示', ['v1a'], 'sample', None, '健康知识分享', 'hc-res', '', '', 512, 1),
        ('v2', 'video', 'yy', 'f', now - 2 * D, '发布于吉隆坡', '急救知识：心肺复苏要点，关键时刻能救命', ['v2a'], 'sample', None, '科学运动康复', 'hc-gym', '', '', 388, 0),
        ('v3', 'video', 'future', 'm', now - 3 * D, '发布于吉隆坡', '名医直播答疑预告 · 慢病管理那些事', ['v3a'], 'sample', None, '智慧医疗交流', 'hc-web', '', '', 201, 0),
    ]
    for p in posts:
        pid, kind, author, gender, ts, loc, text, imgs, video, poll, cn, cs, csub, topic, views, rec = p
        seed_ = q('SELECT seed FROM users WHERE id=?', (author,), one=True)['seed']
        q('INSERT INTO posts VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)',
          (pid, kind, author, seed_, gender, ts, loc, text, json.dumps(imgs), video, json.dumps(poll) if poll else '', cn, cs, csub, topic, views, 'approved', rec), commit=True)
    likes = [('p1', 'allanliu6'), ('p1', 'shier'), ('p1', 'jacky'), ('p2', 'yy'), ('p2', 'future'), ('v1', 'allanliu6'), ('v1', 'shier'), ('f2', 'weichen')]
    for pl in likes:
        q('INSERT INTO post_likes VALUES(?,?)', pl, commit=True)
    for pf in [('p1', 'u-me'), ('v1', 'jacky')]:
        q('INSERT INTO post_favs VALUES(?,?)', pf, commit=True)
    cmts = [('p1', 'allanliu6', '很实用，已经转给家里长辈了。', now - D + 3600000),
            ('p1', 'shier', '请问流感疫苗需要每年打吗？', now - D + 7200000),
            ('p1', 'segi', '是的，每年流感病毒株会变化，建议每年秋季接种。', now - D + 9000000),
            ('p2', 'yy', '流程讲得很清楚，收藏了！', now - 2 * D + 3600000),
            ('v1', 'allanliu6', '原来一直洗错了😂', now - D + 1800000),
            ('f1', 'segi', '可以把报告中异常项拍照发到问诊社区，医生会帮忙解读。', now - D + 5400000)]
    for pid, a, t, ts in cmts:
        sd = q('SELECT seed FROM users WHERE id=?', (a,), one=True)['seed']
        q('INSERT INTO comments VALUES(?,?,?,?,?,?)', ('c-' + uuid.uuid4().hex[:8], pid, a, sd, t, ts), commit=True)

    msgs = [
        ('service', 'u-me', 'service', '您好，欢迎来到健康圈子客服中心！请问有什么可以帮您？', now - 2 * D, 0),
        ('service', 'u-me', 'service', '温馨提示：发布内容需经审核后公开展示。', now - D, 0),
        ('sysnotify', 'u-me', 'system', '您的帖子《周末一起去公园健步走吗？》已通过审核。', now - 3 * D, 0),
        ('sysnotify', 'u-me', 'system', '社区周末义诊报名即将截止，请尽快确认。', now - D, 0),
        ('share', 'u-me', 'system', '新功能上线：分享健康圈到朋友圈可生成专属卡片。', now - 4 * D, 1),
        ('user:allanliu6', 'u-me', 'allanliu6', '你好，看到你发的控糖计划，可以交流一下吗？', now - D, 0),
        ('user:shier', 'u-me', 'shier', '周末健步走一起？', now - 2 * D, 1),
    ]
    for ch, owner, sender, text, ts, rd in msgs:
        q('INSERT INTO messages VALUES(?,?,?,?,?,?,?)', ('m-' + uuid.uuid4().hex[:8], ch, owner, sender, text, ts, rd), commit=True)

    home = {
        'carousel': [
            {'seed': 'home-hero-1', 'title': '示例主题一', 'subtitle': '本周精选', 'image': ''},
            {'seed': 'home-hero-2', 'title': '示例主题二', 'subtitle': '开学季推荐', 'image': ''},
            {'seed': 'home-hero-3', 'title': '示例主题三', 'subtitle': '热门活动', 'image': ''},
        ],
        'hotForums': [
            {'id': 'course', 'label': '健康入门', 'seed': 'hf-course', 'tint': '#F2704A'},
            {'id': 'abroad', 'label': '慢病管理', 'seed': 'hf-abroad', 'tint': '#2DB4E0'},
            {'id': 'major', 'label': '专科问诊', 'seed': 'hf-major', 'tint': '#0EA5B7'},
            {'id': 'video', 'label': '科普视频', 'seed': 'hf-video', 'tint': '#0EA5B7'},
            {'id': 'stream', 'label': '医生直播', 'seed': 'hf-stream', 'tint': '#2DB4E0'},
            {'id': 'digital', 'label': '智慧医疗', 'seed': 'hf-digital', 'tint': '#0EA5B7'},
        ],
        'hotCircles': [
            {'id': 'gym', 'label': '科学运动康复', 'seed': 'hc-gym', 'image': '', 'sub': '一起科学运动，远离慢病'},
            {'id': 'study', 'label': 'Healthy Life Made Easy', 'seed': 'hc-study', 'image': '', 'sub': '健康生活很简单'},
            {'id': 'car', 'label': '中医养生馆', 'seed': 'hc-car', 'image': '', 'sub': '四季养生、食疗调理，一起交流经验'},
            {'id': 'res', 'label': '健康知识分享', 'seed': 'hc-res', 'image': '', 'sub': '分享你的健康小妙招'},
            {'id': 'yy', 'label': '宝妈育儿', 'seed': 'hc-yy', 'image': '', 'sub': '心情好，身体更健康'},
            {'id': 'team', 'label': 'CARE TOGETHER 互助', 'seed': 'hc-team', 'image': '', 'sub': '病友互助，一起加油'},
            {'id': 'web', 'label': '智慧医疗交流', 'seed': 'hc-web', 'image': '', 'sub': '专注于健康知识、科普与就医经验交流的健康圈'},
            {'id': 'art', 'label': '家庭医生', 'seed': 'hc-art', 'image': '', 'sub': '家庭健康守护者'},
        ],
        'followedCircles': [
            {'id': 'res', 'label': '健康知识分享', 'seed': 'hc-res', 'image': '/assets/images/home-info-1.jpg', 'sub': '分享你的健康小妙招'},
            {'id': 'gym', 'label': '科学运动康复', 'seed': 'hc-gym', 'image': '/assets/images/home-info-2.jpg', 'sub': '一起科学运动，远离慢病'},
            {'id': 'web', 'label': '智慧医疗交流', 'seed': 'hc-web', 'image': '/assets/images/home-info-3.jpg', 'sub': '专注于健康知识、科普与就医经验交流的健康圈'},
            {'id': 'car', 'label': '中医养生馆', 'seed': 'hc-car', 'image': '', 'sub': '四季养生、食疗调理，一起交流经验'},
            {'id': 'team', 'label': 'CARE TOGETHER 互助', 'seed': 'hc-team', 'image': '', 'sub': '病友互助，一起加油'},
        ],
        'forumCategories': [{'id': f'c{i+1}', 'label': l, 'seed': f'fc-{i+1}'} for i, l in enumerate(
            ['健康入门', '慢病管理', '专科问诊', '科普视频', '医生直播', '智慧医疗', '健康书单', '健康头条', '跨境就医'])],
        'hotTopics': [
            {'title': '如何科学地开始减重计划', 'grad': ['#12A594', '#0EA5B7']},
            {'title': '第一次体检，需要注意什么', 'grad': ['#2DB4E0', '#0EA5B7']},
            {'title': '如何养成规律作息提升免疫力', 'grad': ['#1DB980', '#12A594']},
            {'title': '高血压日常用药经验', 'grad': ['#FF8A5B', '#FFB37A']},
            {'title': '糖尿病饮食控制分享', 'grad': ['#0EA5B7', '#2DB4E0']},
        ],
        'taxonomy': {
            'circle': [
                {'label': '健康生活', 'items': ['健康知识分享', '科学运动康复', '中医养生馆', 'Healthy Life Made Easy']},
                {'label': '互助社区', 'items': ['CARE TOGETHER 互助', '宝妈育儿', '家庭医生', '康复伙伴']},
                {'label': '智慧医疗', 'items': ['智慧医疗交流', '电子病历与隐私', 'AI 智能导诊']},
                {'label': '健康推广', 'items': ['健康推广', '机构合作', '药企合作', '健康媒体']},
            ],
            'forum': [
                {'label': '健康入门', 'items': ['如何科学地开始减重计划', '第一次体检，需要注意什么', '如何养成规律作息提升免疫力']},
                {'label': '慢病管理', 'items': ['高血压日常用药经验', '糖尿病饮食控制分享', '颈椎腰椎不适怎么调理']},
                {'label': '专科问诊', 'items': ['儿童发烧家长须知', '如何选择靠谱的线上问诊', '名医直播答疑预告']},
                {'label': '跨境就医', 'items': ['海外就医签证攻略', '海外体检经验', '国际药品']},
            ],
        },
    }
    q('INSERT INTO home_cms VALUES(?,?)', ('home', json.dumps(home, ensure_ascii=False)), commit=True)
    print('seeded DB at', DB_PATH)


# ───────────────────────── auth helpers ─────────────────────────
def make_token(uid):
    payload = base64.urlsafe_b64encode(json.dumps({'uid': uid, 'ts': NOW()}).encode()).decode().rstrip('=')
    sig = hmac.new(SECRET.encode(), payload.encode(), hashlib.sha256).hexdigest()[:32]
    return f'{payload}.{sig}'


def parse_token(tok):
    try:
        payload, sig = tok.split('.')
        if not hmac.compare_digest(sig, hmac.new(SECRET.encode(), payload.encode(), hashlib.sha256).hexdigest()[:32]):
            return None
        pad = '=' * (-len(payload) % 4)
        return json.loads(base64.urlsafe_b64decode(payload + pad))['uid']
    except Exception:
        return None


def public_user(u):
    if not u:
        return None
    return {'id': u['id'], 'name': u['name'], 'avatar': u['avatar'] or '', 'gender': u['gender'], 'seed': u['seed'], 'ip': u['ip'], 'email': u.get('email', '')}


def haversine(lat1, lng1, lat2, lng2):
    R = 6371000
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dp, dl = math.radians(lat2 - lat1), math.radians(lng2 - lng1)
    a = math.sin(dp / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2
    return 2 * R * math.asin(math.sqrt(a))


def event_out(e, uid=None):
    signups = [r['user'] for r in q('SELECT user FROM event_signups WHERE event_id=? ORDER BY ts', (e['id'],))]
    names = {u['id']: u for u in q('SELECT id,name,seed FROM users')}
    author = names.get(e['author'], {'name': e['author']})
    return {**e, 'signups': signups, 'joined': uid in signups if uid else False,
            'authorName': author['name'], 'signupUsers': [{'id': s, 'name': names.get(s, {}).get('name', s), 'seed': names.get(s, {}).get('seed', s)} for s in signups]}


def post_out(p, uid=None):
    likes = [r['user'] for r in q('SELECT user FROM post_likes WHERE post_id=?', (p['id'],))]
    favs = [r['user'] for r in q('SELECT user FROM post_favs WHERE post_id=?', (p['id'],))]
    cc = q('SELECT COUNT(*) n FROM comments WHERE post_id=?', (p['id'],), one=True)['n']
    author = q('SELECT id,name,seed,avatar FROM users WHERE id=?', (p['author'],), one=True) or {'name': p['author'], 'seed': p['author_seed']}
    return {**p, 'images': json.loads(p['images'] or '[]'), 'poll': json.loads(p['poll']) if p['poll'] else None,
            'likes': len(likes), 'liked': uid in likes, 'favs': len(favs), 'faved': uid in favs, 'comments': cc,
            'authorName': author['name'], 'authorSeed': author.get('seed') or p['author_seed'], 'authorAvatar': author.get('avatar', '')}


# ───────────────────────── HTTP handler ─────────────────────────
class Handler(BaseHTTPRequestHandler):
    def log_message(self, *a):
        pass

    def _cors(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization')

    def _json(self, obj, code=200):
        body = json.dumps(obj, ensure_ascii=False).encode()
        self.send_response(code)
        self._cors()
        self.send_header('Content-Type', 'application/json; charset=utf-8')
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _err(self, msg, code=400):
        self._json({'error': msg}, code)

    def _body(self):
        n = int(self.headers.get('Content-Length') or 0)
        raw = self.rfile.read(n) if n else b''
        return raw

    def _jbody(self):
        raw = self._body()
        try:
            return json.loads(raw.decode() or '{}')
        except Exception:
            return {}

    def _uid(self):
        auth = self.headers.get('Authorization', '')
        if auth.startswith('Bearer '):
            return parse_token(auth[7:])
        return None

    def do_OPTIONS(self):
        self.send_response(204)
        self._cors()
        self.end_headers()

    def do_GET(self):
        u = urlparse(self.path)
        path, qs = u.path.rstrip('/'), parse_qs(u.query)
        uid = self._uid()
        parts = path.split('/')
        try:
            if path == '/api/health':
                return self._json({'ok': True, 'ts': NOW()})
            if path.startswith('/uploads/'):
                fp = os.path.join(UPLOAD_DIR, os.path.basename(path))
                if not os.path.exists(fp):
                    return self._err('not found', 404)
                data = open(fp, 'rb').read()
                self.send_response(200)
                self._cors()
                self.send_header('Content-Type', 'image/jpeg')
                self.send_header('Content-Length', str(len(data)))
                self.end_headers()
                return self.wfile.write(data)
            if path == '/api/auth/me':
                if not uid:
                    return self._err('unauthorized', 401)
                return self._json({'user': public_user(q('SELECT * FROM users WHERE id=?', (uid,), one=True))})
            if path == '/api/geofence':
                return self._json(q('SELECT * FROM geofence WHERE id=1', one=True))
            if path == '/api/home':
                return self._json(json.loads(q("SELECT value FROM home_cms WHERE key='home'", one=True)['value']))
            if path == '/api/events':
                rows = q("SELECT * FROM events WHERE status='approved' ORDER BY ts DESC")
                return self._json({'items': [event_out(e, uid) for e in rows]})
            if len(parts) == 4 and parts[2] == 'events':
                e = q('SELECT * FROM events WHERE id=?', (parts[3],), one=True)
                if not e:
                    return self._err('not found', 404)
                q('UPDATE events SET views=views+1 WHERE id=?', (parts[3],), commit=True)
                e['views'] += 1
                return self._json(event_out(e, uid))
            if path == '/api/posts':
                kind = qs.get('kind', [''])[0]
                limit = int(qs.get('limit', ['50'])[0])
                where, args = "status='approved'", []
                if kind in ('circle', 'forum', 'video'):
                    where += ' AND kind=?'
                    args.append(kind)
                if qs.get('mine') and uid:
                    where, args = 'author=?', [uid]
                if qs.get('fav') and uid:
                    where, args = 'id IN (SELECT post_id FROM post_favs WHERE user=?)', [uid]
                rows = q(f'SELECT * FROM posts WHERE {where} ORDER BY ts DESC LIMIT ?', (*args, limit))
                return self._json({'items': [post_out(p, uid) for p in rows]})
            if len(parts) == 4 and parts[2] == 'posts':
                p = q('SELECT * FROM posts WHERE id=?', (parts[3],), one=True)
                if not p:
                    return self._err('not found', 404)
                q('UPDATE posts SET views=views+1 WHERE id=?', (parts[3],), commit=True)
                p['views'] += 1
                return self._json(post_out(p, uid))
            if len(parts) == 5 and parts[2] == 'posts' and parts[4] == 'comments':
                rows = q('SELECT c.*, u.name authorName FROM comments c LEFT JOIN users u ON u.id=c.author WHERE post_id=? ORDER BY ts', (parts[3],))
                return self._json({'items': rows})
            if path == '/api/messages/summary':
                if not uid:
                    return self._err('unauthorized', 401)
                rows = q('SELECT channel, COUNT(*) n FROM messages WHERE owner=? AND read=0 AND sender!=? GROUP BY channel', (uid, uid))
                unread = {r['channel']: r['n'] for r in rows}
                chats = q("SELECT channel, MAX(ts) ts FROM messages WHERE owner=? AND channel LIKE 'user:%' GROUP BY channel ORDER BY ts DESC", (uid,))
                users = {x['id']: x for x in q('SELECT id,name,seed FROM users')}
                conv = []
                for c in chats:
                    last = q('SELECT text,ts FROM messages WHERE owner=? AND channel=? ORDER BY ts DESC LIMIT 1', (uid, c['channel']), one=True)
                    other = c['channel'][5:]
                    conv.append({'channel': c['channel'], 'userId': other, 'name': users.get(other, {}).get('name', other), 'seed': users.get(other, {}).get('seed', other),
                                 'last': last['text'], 'ts': last['ts'], 'unread': unread.get(c['channel'], 0)})
                return self._json({'unread': unread, 'conversations': conv, 'total': sum(unread.values())})
            if len(parts) >= 4 and parts[2] == 'messages':
                if not uid:
                    return self._err('unauthorized', 401)
                ch = '/'.join(parts[3:])
                rows = q('SELECT * FROM messages WHERE owner=? AND channel=? ORDER BY ts', (uid, ch))
                q('UPDATE messages SET read=1 WHERE owner=? AND channel=?', (uid, ch), commit=True)
                users = {x['id']: x for x in q('SELECT id,name,seed FROM users')}
                for r in rows:
                    r['senderName'] = users.get(r['sender'], {}).get('name', r['sender'])
                    r['senderSeed'] = users.get(r['sender'], {}).get('seed', r['sender'])
                    r['mine'] = r['sender'] == uid
                return self._json({'items': rows})
            return self._err('not found', 404)
        except Exception as ex:  # pragma: no cover
            return self._err(f'server error: {ex}', 500)

    def do_POST(self):
        path = urlparse(self.path).path.rstrip('/')
        parts = path.split('/')
        uid = self._uid()
        try:
            if path == '/api/upload':
                raw = self._body()
                if len(raw) > 5 * 1024 * 1024:
                    return self._err('文件过大（≤5MB）', 413)
                name = uuid.uuid4().hex + '.jpg'
                open(os.path.join(UPLOAD_DIR, name), 'wb').write(raw)
                return self._json({'url': f'/uploads/{name}'})
            b = self._jbody()
            if path == '/api/auth/send-code':
                em = (b.get('email') or '').strip().lower()
                if '@' not in em:
                    return self._err('邮箱格式不正确')
                code = f'{secrets.randbelow(900000) + 100000}'
                q('INSERT OR REPLACE INTO codes VALUES(?,?,?)', (em, code, NOW()), commit=True)
                # Dev mode: return the code so the prototype can be tested without an SMTP server.
                return self._json({'ok': True, 'devCode': code})
            if path == '/api/auth/register':
                em = (b.get('email') or '').strip().lower()
                code, pwd = b.get('code', ''), b.get('password', '')
                row = q('SELECT * FROM codes WHERE email=?', (em,), one=True)
                if not row or row['code'] != code or NOW() - row['ts'] > 10 * 60 * 1000:
                    return self._err('验证码错误或已过期')
                if len(pwd) < 6:
                    return self._err('密码至少 6 位')
                if q('SELECT 1 FROM users WHERE email=?', (em,)):
                    return self._err('该邮箱已注册')
                nid = 'u-' + uuid.uuid4().hex[:8]
                name = b.get('name') or em.split('@')[0]
                q('INSERT INTO users VALUES(?,?,?,?,?,?,?,?,?)', (nid, em, name, hash_pwd(pwd), '', 'm', nid, '吉隆坡', NOW()), commit=True)
                q('INSERT INTO messages VALUES(?,?,?,?,?,?,?)', ('m-' + uuid.uuid4().hex[:8], 'service', nid, 'service', '欢迎加入健康圈子！如有问题可随时联系客服。', NOW(), 0), commit=True)
                q('DELETE FROM codes WHERE email=?', (em,), commit=True)
                return self._json({'token': make_token(nid), 'user': public_user(q('SELECT * FROM users WHERE id=?', (nid,), one=True))})
            if path == '/api/auth/login':
                em = (b.get('email') or '').strip().lower()
                u = q('SELECT * FROM users WHERE email=?', (em,), one=True)
                if not u or u['pwd'] != hash_pwd(b.get('password', '')):
                    return self._err('邮箱或密码错误', 401)
                return self._json({'token': make_token(u['id']), 'user': public_user(u)})
            if path == '/api/geofence/check':
                g = q('SELECT * FROM geofence WHERE id=1', one=True)
                try:
                    lat, lng = float(b['lat']), float(b['lng'])
                except Exception:
                    return self._err('缺少坐标')
                d = haversine(lat, lng, g['lat'], g['lng'])
                return self._json({'inside': d <= g['radius_m'], 'distance_m': round(d), 'radius_m': g['radius_m'], 'name': g['name'], 'blocked_message': g['blocked']})
            if path == '/api/events':
                if not uid:
                    return self._err('unauthorized', 401)
                nid = 'uev-' + uuid.uuid4().hex[:8]
                q('INSERT INTO events VALUES(?,?,?,?,?,?,?,?,?,?,?,?)',
                  (nid, b.get('title', ''), b.get('date', ''), b.get('time', ''), b.get('place', ''), b.get('detail', ''), nid, b.get('cover', ''), 0, uid, 'pending', NOW()), commit=True)
                return self._json({'id': nid, 'status': 'pending'})
            if len(parts) == 5 and parts[2] == 'events' and parts[4] == 'join':
                if not uid:
                    return self._err('unauthorized', 401)
                eid = parts[3]
                if q('SELECT 1 FROM event_signups WHERE event_id=? AND user=?', (eid, uid)):
                    q('DELETE FROM event_signups WHERE event_id=? AND user=?', (eid, uid), commit=True)
                    joined = False
                else:
                    q('INSERT INTO event_signups VALUES(?,?,?)', (eid, uid, NOW()), commit=True)
                    joined = True
                return self._json({'joined': joined, 'event': event_out(q('SELECT * FROM events WHERE id=?', (eid,), one=True), uid)})
            if path == '/api/posts':
                if not uid:
                    return self._err('unauthorized', 401)
                u = q('SELECT * FROM users WHERE id=?', (uid,), one=True)
                nid = 'up-' + uuid.uuid4().hex[:8]
                kind = b.get('kind', 'circle')
                q('INSERT INTO posts VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)',
                  (nid, kind, uid, u['seed'], u['gender'], NOW(), f'发布于{u["ip"].split(" · ")[0]}', b.get('text', ''), json.dumps(b.get('images', [])),
                   b.get('video', ''), json.dumps(b.get('poll')) if b.get('poll') else '', b.get('circleName', ''), b.get('circleSeed', ''), b.get('circleSub', ''),
                   b.get('topic', ''), 0, 'pending', 0), commit=True)
                return self._json({'id': nid, 'status': 'pending'})
            if len(parts) == 5 and parts[2] == 'posts' and parts[4] in ('like', 'fav'):
                if not uid:
                    return self._err('unauthorized', 401)
                tbl = 'post_likes' if parts[4] == 'like' else 'post_favs'
                pid = parts[3]
                if q(f'SELECT 1 FROM {tbl} WHERE post_id=? AND user=?', (pid, uid)):
                    q(f'DELETE FROM {tbl} WHERE post_id=? AND user=?', (pid, uid), commit=True)
                else:
                    q(f'INSERT INTO {tbl} VALUES(?,?)', (pid, uid), commit=True)
                return self._json(post_out(q('SELECT * FROM posts WHERE id=?', (pid,), one=True), uid))
            if len(parts) == 5 and parts[2] == 'posts' and parts[4] == 'comments':
                if not uid:
                    return self._err('unauthorized', 401)
                u = q('SELECT * FROM users WHERE id=?', (uid,), one=True)
                cid = 'c-' + uuid.uuid4().hex[:8]
                q('INSERT INTO comments VALUES(?,?,?,?,?,?)', (cid, parts[3], uid, u['seed'], b.get('text', ''), NOW()), commit=True)
                return self._json({'id': cid, 'post_id': parts[3], 'author': uid, 'authorName': u['name'], 'author_seed': u['seed'], 'text': b.get('text', ''), 'ts': NOW()})
            if path == '/api/feedback':
                if not uid:
                    return self._err('unauthorized', 401)
                q('INSERT INTO feedback VALUES(?,?,?,?)', ('fb-' + uuid.uuid4().hex[:8], uid, b.get('text', ''), NOW()), commit=True)
                q('INSERT INTO messages VALUES(?,?,?,?,?,?,?)', ('m-' + uuid.uuid4().hex[:8], 'feedback', uid, uid, b.get('text', ''), NOW(), 1), commit=True)
                q('INSERT INTO messages VALUES(?,?,?,?,?,?,?)', ('m-' + uuid.uuid4().hex[:8], 'feedback', uid, 'system', '感谢您的反馈，我们已收到并会尽快处理。', NOW() + 1, 0), commit=True)
                return self._json({'ok': True})
            if len(parts) >= 4 and parts[2] == 'messages':
                if not uid:
                    return self._err('unauthorized', 401)
                ch = '/'.join(parts[3:])
                text = (b.get('text') or '').strip()
                if not text:
                    return self._err('内容不能为空')
                mid = 'm-' + uuid.uuid4().hex[:8]
                q('INSERT INTO messages VALUES(?,?,?,?,?,?,?)', (mid, ch, uid, uid, text, NOW(), 1), commit=True)
                reply = None
                if ch == 'service':
                    reply = '已收到您的消息，客服将在 10 分钟内回复您。'
                elif ch.startswith('user:'):
                    other = ch[5:]
                    # mirror into the other user's inbox
                    q('INSERT INTO messages VALUES(?,?,?,?,?,?,?)', ('m-' + uuid.uuid4().hex[:8], f'user:{uid}', other, uid, text, NOW(), 0), commit=True)
                if reply:
                    q('INSERT INTO messages VALUES(?,?,?,?,?,?,?)', ('m-' + uuid.uuid4().hex[:8], ch, uid, 'service', reply, NOW() + 1, 0), commit=True)
                return self._json({'ok': True, 'id': mid, 'reply': reply})
            return self._err('not found', 404)
        except Exception as ex:  # pragma: no cover
            return self._err(f'server error: {ex}', 500)

    def do_DELETE(self):
        path = urlparse(self.path).path.rstrip('/')
        parts = path.split('/')
        uid = self._uid()
        if len(parts) >= 5 and parts[2] == 'messages' and uid:
            # recall own message within 3 min
            mid = parts[-1]
            m = q('SELECT * FROM messages WHERE id=? AND sender=?', (mid, uid), one=True)
            if not m:
                return self._err('not found', 404)
            if NOW() - m['ts'] > 3 * 60 * 1000:
                return self._err('超过 3 分钟，无法撤回')
            q('DELETE FROM messages WHERE id=?', (mid,), commit=True)
            return self._json({'ok': True})
        return self._err('not found', 404)


if __name__ == '__main__':
    seed()
    print(f'Health Circle API listening on 0.0.0.0:{PORT}')
    ThreadingHTTPServer(('0.0.0.0', PORT), Handler).serve_forever()
