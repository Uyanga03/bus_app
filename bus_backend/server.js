const dns = require('dns');
dns.setServers(['8.8.8.8', '8.8.4.4']);
require('dotenv').config();

const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const bcrypt = require('bcryptjs');         // ШИНЭ
const jwt = require('jsonwebtoken');        // ШИНЭ
const multer = require('multer');           // ШИНЭ
const path = require('path');              // ШИНЭ

const app = express();
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));                    // ШИНЭ
app.use('/images', express.static(path.join(__dirname, 'assets/images')));

// ── JWT тохиргоо (.env файлаас уншина) ──
const JWT_SECRET = process.env.JWT_SECRET;
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN;

// ── ШИНЭ: Multer (зураг/бичлэг upload) ──
const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, 'assets/images/'),
  filename: (req, file, cb) => {
    cb(null, Date.now() + '-' + Math.round(Math.random() * 1e9) + path.extname(file.originalname));
  },
});
const upload = multer({
  storage,
  limits: { fileSize: 20 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    const allowed = /jpeg|jpg|png|gif|mp4|mov|avi/;
    if (allowed.test(path.extname(file.originalname).toLowerCase())) {
      cb(null, true);
    } else {
      cb(new Error('Зөвхөн зураг болон бичлэг оруулах боломжтой'));
    }
  },
});

const MONGO_URI = process.env.MONGO_URI;

mongoose.connect(MONGO_URI)
  .then(() => console.log('MongoDB connected'))
  .catch((err) => console.error('MongoDB error:', err));

// ═══════════════════════════════════════════════════════════════════════════
//  SCHEMAS
// ═══════════════════════════════════════════════════════════════════════════

// ── Route Schema (ХУУЧНААР) ──────────────────────────────────────────────
const routeSchema = new mongoose.Schema({
  name:  { type: String, required: true },
  full:  { type: String, required: true },
  phone: { type: String, default: '' },
});

const Route = mongoose.model('Route', routeSchema);

// ── Feedback Schema (ШИНЭЧЛЭГДСЭН — Flutter кодтой таарна) ──────────────
const commentSchema = new mongoose.Schema({
  userName:  { type: String, default: 'Хэрэглэгч' },
  userId:    { type: String, default: '' },
  message:   { type: String, required: true },
  createdAt: { type: Date, default: Date.now },
});

const feedbackSchema = new mongoose.Schema({
  type:         { type: String, required: true },
  message:      { type: String, default: '' },
  busNumber:    { type: String, default: '' },
  category:     { type: String, default: '' },  // Ангилал: Цахилгаан эд зүйл, Цүнх, Түлхүүр, ...
  userName:     { type: String, default: 'Зочин' },
  userId:       { type: String, default: '' },          // ШИНЭ
  likes:        { type: Number, default: 0 },
  likedBy:      { type: [String], default: [] },        // ШИНЭ — Flutter дээр шалгадаг
  comments:     { type: Number, default: 0 },
  commentsList: { type: [commentSchema], default: [] }, // ШИНЭ
  mediaUrls:    { type: [String], default: [] },        // ШИНЭ
  image:        { type: String, default: '' },          // Хуучин field хэвээр
  status:       { type: String, enum: ['pending', 'approved', 'rejected'], default: 'pending' },
  resolved:     { type: Boolean, default: false },  // Алдсан→олдсон, Санал/Гомдол→шийдвэрлэгдсэн
  resolvedAt:   { type: Date, default: null },
  approvedBy:   { type: String, default: '' },
  approvedAt:   { type: Date, default: null },
  // ── Хадгалах хугацааны систем (олдсон/алдсан эд зүйлд) ──
  storagePhase: { type: String, enum: ['station', 'police', 'returned', 'expired'], default: 'station' },
  stationDeadline: { type: Date, default: null },
  policeDeadline:  { type: Date, default: null },
  transferredAt:   { type: Date, default: null },
  returnedAt:      { type: Date, default: null },
  isDeleted:       { type: Boolean, default: false },
  deletedAt:       { type: Date, default: null },
  createdAt:    { type: Date, default: Date.now },
});

const Feedback = mongoose.model('Feedback', feedbackSchema);

// ── ШИНЭ: User Schema ──
const userSchema = new mongoose.Schema({
  lastName:        { type: String, required: true, trim: true },
  firstName:       { type: String, required: true, trim: true },
  phone:           { type: String, required: true, unique: true, trim: true },
  password:        { type: String, required: true, minlength: 6 },
  role:            { type: String, default: 'Зорчигч' },
  isPhoneVerified: { type: Boolean, default: false },
}, { timestamps: true });

userSchema.pre('save', async function () {
  if (!this.isModified('password')) return;
  this.password = await bcrypt.hash(this.password, 10);
});

userSchema.methods.matchPassword = async function (entered) {
  return await bcrypt.compare(entered, this.password);
};

const User = mongoose.model('User', userSchema);

// ── ШИНЭ: OTP Schema ──
const otpSchema = new mongoose.Schema({
  phone:     { type: String, required: true },
  code:      { type: String, required: true },
  type:      { type: String, enum: ['register', 'reset', 'login'], default: 'register' },
  expiresAt: { type: Date, default: () => new Date(Date.now() + 5 * 60 * 1000) },
  isUsed:    { type: Boolean, default: false },
});
otpSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });

const Otp = mongoose.model('Otp', otpSchema);

// ── ШИНЭ: Driver Schema (тусдаа collection) ──
const driverSchema = new mongoose.Schema({
  lastName:        { type: String, required: true, trim: true },
  firstName:       { type: String, required: true, trim: true },
  phone:           { type: String, required: true, unique: true, trim: true },
  password:        { type: String, required: true, minlength: 6 },
  driverLicense:   { type: String, required: true, trim: true },  // Жолоочийн үнэмлэхний дугаар
  companyCode:     { type: String, required: true, trim: true },  // Компанийн код
  companyName:     { type: String, default: '' },                  // Компанийн нэр
  busRoute:        { type: String, default: '' },                  // Хариуцсан чиглэл
  busNumber:       { type: String, default: '' },                  // Автобусны дугаар
  role:            { type: String, default: 'Жолооч' },
  isActive:        { type: Boolean, default: true },               // Идэвхтэй эсэх
}, { timestamps: true });

driverSchema.pre('save', async function () {
  if (!this.isModified('password')) return;
  this.password = await bcrypt.hash(this.password, 10);
});

driverSchema.methods.matchPassword = async function (entered) {
  return await bcrypt.compare(entered, this.password);
};

const Driver = mongoose.model('Driver', driverSchema);

// ── ШИНЭ: Admin Schema (тусдаа collection) ──
const adminSchema = new mongoose.Schema({
  lastName:    { type: String, required: true, trim: true },
  firstName:   { type: String, required: true, trim: true },
  phone:       { type: String, required: true, unique: true, trim: true },
  password:    { type: String, required: true, minlength: 6 },
  role:        { type: String, default: 'Админ' },
  permissions: { type: [String], default: ['all'] },  // Эрхийн түвшин
}, { timestamps: true });

adminSchema.pre('save', async function () {
  if (!this.isModified('password')) return;
  this.password = await bcrypt.hash(this.password, 10);
});

adminSchema.methods.matchPassword = async function (entered) {
  return await bcrypt.compare(entered, this.password);
};

const Admin = mongoose.model('Admin', adminSchema);

// ── Notification Schema ──
const notificationSchema = new mongoose.Schema({
  userId:    { type: String, required: true },
  fromUser:  { type: String, default: '' },
  fromName:  { type: String, default: '' },
  type:      { type: String, required: true },
  message:   { type: String, default: '' },
  postId:    { type: String, default: '' },
  isRead:    { type: Boolean, default: false },
  createdAt: { type: Date, default: Date.now },
});

const Notification = mongoose.model('Notification', notificationSchema);

// ═══════════════════════════════════════════════════════════════════════════
//  UTILS
// ═══════════════════════════════════════════════════════════════════════════

function generateOtp() {
  return Math.floor(1000 + Math.random() * 9000).toString();
}

function createToken(userId) {
  return jwt.sign({ id: userId }, JWT_SECRET, { expiresIn: JWT_EXPIRES_IN });
}

async function sendSms(phone, message) {
  console.log('═══════════════════════════════════');
  console.log(`📱 SMS → ${phone}`);
  console.log(`📝 ${message}`);
  console.log('═══════════════════════════════════');
  // Production дээр CallPro API-г энд холбоно
  return true;
}

// ═══════════════════════════════════════════════════════════════════════════
//  ROUTE API (ХУУЧНААР — ӨӨРЧЛӨЛТГҮЙ)
// ═══════════════════════════════════════════════════════════════════════════

app.get('/api/routes', async (req, res) => {
  try {
    const routes = await Route.find();
    res.json(routes);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/routes/:id', async (req, res) => {
  try {
    const route = await Route.findById(req.params.id);
    if (!route) return res.status(404).json({ error: 'Not found' });
    res.json(route);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/routes', async (req, res) => {
  try {
    const route = new Route(req.body);
    await route.save();
    res.status(201).json(route);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

app.put('/api/routes/:id', async (req, res) => {
  try {
    const route = await Route.findByIdAndUpdate(req.params.id, req.body, { new: true });
    res.json(route);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

app.delete('/api/routes/:id', async (req, res) => {
  try {
    await Route.findByIdAndDelete(req.params.id);
    res.json({ message: 'Deleted' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ═══════════════════════════════════════════════════════════════════════════
//  FEEDBACK API (ШИНЭЧЛЭГДСЭН — Flutter кодтой 100% таарна)
// ═══════════════════════════════════════════════════════════════════════════

// ── GET /api/feedback — Бүх постууд (устгаагүй) ──
app.get('/api/feedback', async (req, res) => {
  try {
    const filter = { isDeleted: { $ne: true } };
    if (req.query.type) filter.type = req.query.type;
    if (req.query.category) filter.category = req.query.category;
    const feedbacks = await Feedback.find(filter).sort({ createdAt: -1 });
    res.json(feedbacks);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ── GET /api/feedback/admin — Админ: бүх постууд (устгасан ч орно) ──
app.get('/api/feedback/admin', async (req, res) => {
  try {
    const feedbacks = await Feedback.find().sort({ createdAt: -1 });
    res.json(feedbacks);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ── POST /api/feedback (JSON + Multipart аль аль нь) ──
// Flutter илгээх: type, message, busNumber, userName, userId, media[] файлууд
app.post('/api/feedback', upload.array('media', 5), async (req, res) => {
  try {
    const { type, message, busNumber, userName, userId } = req.body;

    const mediaUrls = req.files
      ? req.files.map((f) => `/images/${f.filename}`)
      : [];

    const feedback = new Feedback({
      type,
      message: message || '',
      busNumber: busNumber || '',
      category: category || '',
      userName: userName || 'Зочин',
      userId: userId || '',
      mediaUrls,
      status: 'approved',
    });
    await feedback.save();
    res.status(201).json(feedback);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// ── PUT /api/feedback/:id/like ──
// Flutter илгээх: { userId }
// Flutter дээр likedBy массиваас userId-г шалгаж давхар like-аас хамгаалдаг
app.put('/api/feedback/:id/like', async (req, res) => {
  try {
    const { userId } = req.body;
    const feedback = await Feedback.findById(req.params.id);
    if (!feedback) return res.status(404).json({ error: 'Not found' });

    // Давхар like хийхээс хамгаалах
    if (userId && feedback.likedBy.includes(userId)) {
      return res.status(400).json({ message: 'Аль хэдийн like дарсан' });
    }

    feedback.likes += 1;
    if (userId) feedback.likedBy.push(userId);
    await feedback.save();

    // Мэдэгдэл үүсгэх (постын эзэнд)
    if (feedback.userId && feedback.userId !== userId) {
      try {
        await Notification.create({
          userId: feedback.userId,
          fromUser: userId,
          fromName: req.body.userName || '',
          type: 'like',
          message: `${req.body.userName || 'Хэрэглэгч'} таны постонд зүрх дарлаа ❤️`,
          postId: feedback._id,
        });
      } catch (_) {}
    }

    res.json(feedback);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// ── ШИНЭ: POST /api/feedback/:id/comment ──
// Flutter илгээх: { message, userName, userId }
app.post('/api/feedback/:id/comment', async (req, res) => {
  try {
    const { message, userName, userId } = req.body;
    const feedback = await Feedback.findById(req.params.id);
    if (!feedback) return res.status(404).json({ error: 'Not found' });

    feedback.commentsList.push({
      message,
      userName: userName || 'Хэрэглэгч',
      userId: userId || '',
    });
    feedback.comments = feedback.commentsList.length;
    await feedback.save();

    // Мэдэгдэл үүсгэх (постын эзэнд)
    if (feedback.userId && feedback.userId !== userId) {
      try {
        await Notification.create({
          userId: feedback.userId,
          fromUser: userId || '',
          fromName: userName || '',
          type: 'comment',
          message: `${userName || 'Хэрэглэгч'} сэтгэгдэл бичлээ: "${message.substring(0, 50)}"`,
          postId: feedback._id,
        });
      } catch (_) {}
    }

    res.json(feedback);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// ── DELETE /api/feedback/:id — Зөөлөн устгах (20 хоног хадгална) ──
app.delete('/api/feedback/:id', async (req, res) => {
  try {
    const feedback = await Feedback.findById(req.params.id);
    if (!feedback) return res.status(404).json({ error: 'Олдсонгүй' });
    feedback.isDeleted = true;
    feedback.deletedAt = new Date();
    await feedback.save();
    res.json({ message: 'Устгагдлаа (20 хоног хадгалагдана)' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ── PUT /api/feedback/:id/restore — Устгасан постыг сэргээх ──
app.put('/api/feedback/:id/restore', async (req, res) => {
  try {
    const feedback = await Feedback.findById(req.params.id);
    if (!feedback) return res.status(404).json({ error: 'Олдсонгүй' });
    feedback.isDeleted = false;
    feedback.deletedAt = null;
    await feedback.save();
    res.json({ message: 'Сэргээгдлээ', feedback });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ── DELETE /api/feedback/:id/permanent — Бүр мөсөн устгах ──
app.delete('/api/feedback/:id/permanent', async (req, res) => {
  try {
    await Feedback.findByIdAndDelete(req.params.id);
    res.json({ message: 'Бүр мөсөн устгагдлаа' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ── PUT /api/feedback/:id/approve — Пост баталгаажуулах ──
app.put('/api/feedback/:id/approve', async (req, res) => {
  try {
    const { adminId, adminName } = req.body;
    const feedback = await Feedback.findById(req.params.id);
    if (!feedback) return res.status(404).json({ error: 'Пост олдсонгүй' });

    feedback.status = 'approved';
    feedback.approvedBy = adminName || adminId || '';
    feedback.approvedAt = new Date();

    // Олдсон/Алдсан эд зүйлд хадгалах хугацаа тохируулах
    if (feedback.type === 'олдсон' || feedback.type === 'алдсан') {
      feedback.storagePhase = 'station';
      const now = new Date();
      feedback.stationDeadline = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000); // 7 хоног
      feedback.policeDeadline = new Date(now.getTime() + 6 * 30 * 24 * 60 * 60 * 1000); // 6 сар
    }

    await feedback.save();

    // Постын эзэнд мэдэгдэл илгээх
    if (feedback.userId) {
      try {
        await Notification.create({
          userId: feedback.userId,
          fromUser: adminId || '',
          fromName: adminName || 'Админ',
          type: 'approve',
          message: 'Таны пост баталгаажлаа ✅',
          postId: feedback._id,
        });
      } catch (_) {}
    }

    res.json({ message: 'Баталгаажуулагдлаа', feedback });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ── PUT /api/feedback/:id/reject — Пост цуцлах ──
app.put('/api/feedback/:id/reject', async (req, res) => {
  try {
    const { adminId, adminName, reason } = req.body;
    const feedback = await Feedback.findById(req.params.id);
    if (!feedback) return res.status(404).json({ error: 'Пост олдсонгүй' });

    feedback.status = 'rejected';
    await feedback.save();

    // Постын эзэнд мэдэгдэл илгээх
    if (feedback.userId) {
      try {
        await Notification.create({
          userId: feedback.userId,
          fromUser: adminId || '',
          fromName: adminName || 'Админ',
          type: 'reject',
          message: `Таны пост цуцлагдлаа ❌${reason ? ': ' + reason : ''}`,
          postId: feedback._id,
        });
      } catch (_) {}
    }

    res.json({ message: 'Цуцлагдлаа', feedback });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ── PUT /api/feedback/:id/resolve — Пост шийдвэрлэгдсэн/олдсон болгох ──
app.put('/api/feedback/:id/resolve', async (req, res) => {
  try {
    const { resolved } = req.body;
    const feedback = await Feedback.findById(req.params.id);
    if (!feedback) return res.status(404).json({ error: 'Пост олдсонгүй' });

    feedback.resolved = resolved !== false;
    feedback.resolvedAt = feedback.resolved ? new Date() : null;
    await feedback.save();

    // Постын эзэнд мэдэгдэл
    if (feedback.userId) {
      const isLost = feedback.type === 'алдсан';
      const msg = feedback.resolved
        ? (isLost ? 'Таны алдсан зүйл олдлоо! 🟢' : 'Таны санал хүсэлт шийдвэрлэгдлээ ✅')
        : (isLost ? 'Таны алдсан зүйл олдоогүй байна 🔴' : 'Таны санал хүсэлт шийдвэрлэгдээгүй');
      try {
        await Notification.create({
          userId: feedback.userId,
          type: 'resolve',
          message: msg,
          postId: feedback._id,
        });
      } catch (_) {}
    }

    res.json({ message: 'Шинэчлэгдлээ', feedback });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ── PUT /api/feedback/:id/storage — Хадгалах шатыг өөрчлөх ──
app.put('/api/feedback/:id/storage', async (req, res) => {
  try {
    const { phase } = req.body; // 'station', 'police', 'returned', 'expired'
    const feedback = await Feedback.findById(req.params.id);
    if (!feedback) return res.status(404).json({ error: 'Пост олдсонгүй' });

    feedback.storagePhase = phase;

    if (phase === 'police') {
      feedback.transferredAt = new Date();
    } else if (phase === 'returned') {
      feedback.returnedAt = new Date();
      feedback.resolved = true;
      feedback.resolvedAt = new Date();
    }

    await feedback.save();

    // Мэдэгдэл илгээх
    if (feedback.userId) {
      let msg = '';
      if (phase === 'police') msg = 'Таны олдсон зүйл цагдаад шилжүүлэгдлээ 🔵 (6 сар хадгална)';
      else if (phase === 'returned') msg = 'Эд зүйл эзэнд нь буцаагдлаа ✅';
      else if (phase === 'expired') msg = 'Хадгалах хугацаа дууссан ⚠️';

      if (msg) {
        try {
          await Notification.create({
            userId: feedback.userId,
            type: 'storage',
            message: msg,
            postId: feedback._id,
          });
        } catch (_) {}
      }
    }

    res.json({ message: 'Шинэчлэгдлээ', feedback });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ── Автомат хугацаа шалгах (сервер эхлэхэд 1 цагт нэг удаа) ──
async function checkStorageDeadlines() {
  try {
    const now = new Date();

    // Станцын хугацаа дууссан → Цагдаад шилжүүлэх
    const stationExpired = await Feedback.find({
      storagePhase: 'station',
      stationDeadline: { $lte: now },
      resolved: false,
    });
    for (const fb of stationExpired) {
      fb.storagePhase = 'police';
      fb.transferredAt = now;
      await fb.save();
      if (fb.userId) {
        try {
          await Notification.create({
            userId: fb.userId,
            type: 'storage',
            message: '7 хоног дууслаа. Эд зүйл цагдаад шилжүүлэгдлээ 🔵',
            postId: fb._id,
          });
        } catch (_) {}
      }
    }

    // Цагдаагийн хугацаа дууссан → Хугацаа дууссан
    const policeExpired = await Feedback.find({
      storagePhase: 'police',
      policeDeadline: { $lte: now },
      resolved: false,
    });
    for (const fb of policeExpired) {
      fb.storagePhase = 'expired';
      await fb.save();
      if (fb.userId) {
        try {
          await Notification.create({
            userId: fb.userId,
            type: 'storage',
            message: '6 сарын хадгалах хугацаа дууслаа ⚠️',
            postId: fb._id,
          });
        } catch (_) {}
      }
    }

    if (stationExpired.length || policeExpired.length) {
      console.log(`[Storage Check] Station→Police: ${stationExpired.length}, Police→Expired: ${policeExpired.length}`);
    }

    // 20 хоног өнгөрсөн устгасан постуудыг бүрмөсөн устгах
    const twentyDaysAgo = new Date(now.getTime() - 20 * 24 * 60 * 60 * 1000);
    const permanentlyDeleted = await Feedback.deleteMany({
      isDeleted: true,
      deletedAt: { $lte: twentyDaysAgo },
    });
    if (permanentlyDeleted.deletedCount > 0) {
      console.log(`[Cleanup] ${permanentlyDeleted.deletedCount} пост бүрмөсөн устгагдлаа (20+ хоног)`);
    }
  } catch (err) {
    console.error('Storage check error:', err);
  }
}

// 1 цаг тутамд хугацаа шалгах
setInterval(checkStorageDeadlines, 60 * 60 * 1000);
// Сервер эхлэхэд 1 удаа шалгах
setTimeout(checkStorageDeadlines, 5000);

// ═══════════════════════════════════════════════════════════════════════════
//  ШИНЭ: AUTH API — login_screen.dart + register_screen.dart -тай таарна
// ═══════════════════════════════════════════════════════════════════════════

// ── POST /api/auth/register ──
// Flutter илгээх: { lastName, firstName, phone, password }
// Flutter хүлээх: status 201, { user: { _id, name, phone } }
app.post('/api/auth/register', async (req, res) => {
  try {
    const { lastName, firstName, phone, password } = req.body;

    if (!lastName || !firstName || !phone || !password) {
      return res.status(400).json({ message: 'Бүх талбарыг бөглөнө үү' });
    }
    if (password.length < 6) {
      return res.status(400).json({ message: 'Нууц үг 6-с дээш тэмдэгт байх ёстой' });
    }

    const exists = await User.findOne({ phone });
    if (exists) {
      return res.status(400).json({ message: 'Энэ утасны дугаар бүртгэлтэй байна' });
    }

    const user = await User.create({ lastName, firstName, phone, password });
    const token = createToken(user._id);

    res.status(201).json({
      message: 'Бүртгэл амжилттай!',
      token,
      user: {
        _id: user._id,
        name: `${user.lastName} ${user.firstName}`,
        phone: user.phone,
        role: user.role,
      },
    });
  } catch (err) {
    console.error('Register алдаа:', err);
    res.status(500).json({ message: 'Серверийн алдаа' });
  }
});

// ── POST /api/auth/login ──
// Flutter илгээх: { phone, password, role, driverLicense?, companyCode? }
// Flutter хүлээх: status 200, { user: { _id, name, phone, role } }
app.post('/api/auth/login', async (req, res) => {
  try {
    const { phone, password, role, driverLicense, companyCode } = req.body;

    if (!phone || !password) {
      return res.status(400).json({ message: 'Утас болон нууц үгээ оруулна уу' });
    }

    // ══════════════════════════════════════════
    //  Жолоочоор нэвтрэх → drivers collection
    // ══════════════════════════════════════════
    if (role === 'Жолооч') {
      if (!driverLicense || !companyCode) {
        return res.status(400).json({ message: 'Үнэмлэхний дугаар болон компанийн код оруулна уу' });
      }

      const driver = await Driver.findOne({ phone });
      if (!driver) {
        return res.status(401).json({ message: 'Жолоочийн бүртгэл олдсонгүй' });
      }

      const isMatch = await driver.matchPassword(password);
      if (!isMatch) {
        return res.status(401).json({ message: 'Нууц үг буруу байна' });
      }

      if (driverLicense !== driver.driverLicense) {
        return res.status(401).json({ message: 'Жолоочийн үнэмлэхний дугаар буруу байна' });
      }

      if (companyCode !== driver.companyCode) {
        return res.status(401).json({ message: 'Компанийн код буруу байна' });
      }

      if (!driver.isActive) {
        return res.status(403).json({ message: 'Таны бүртгэл идэвхгүй байна' });
      }

      const token = createToken(driver._id);

      return res.status(200).json({
        message: 'Амжилттай нэвтэрлээ',
        token,
        user: {
          _id: driver._id,
          name: `${driver.lastName} ${driver.firstName}`,
          phone: driver.phone,
          role: 'Жолооч',
          busRoute: driver.busRoute,
          busNumber: driver.busNumber,
          companyName: driver.companyName,
        },
      });
    }

    // ══════════════════════════════════════════
    //  Админ → admins collection
    // ══════════════════════════════════════════
    if (role === 'Админ') {
      const admin = await Admin.findOne({ phone });
      if (!admin) {
        return res.status(401).json({ message: 'Админ бүртгэл олдсонгүй' });
      }

      const isMatch = await admin.matchPassword(password);
      if (!isMatch) {
        return res.status(401).json({ message: 'Нууц үг буруу байна' });
      }

      const token = createToken(admin._id);

      return res.status(200).json({
        message: 'Амжилттай нэвтэрлээ',
        token,
        user: {
          _id: admin._id,
          name: `${admin.lastName} ${admin.firstName}`,
          phone: admin.phone,
          role: 'Админ',
        },
      });
    }

    // ══════════════════════════════════════════
    //  Зорчигч → users collection
    // ══════════════════════════════════════════
    const user = await User.findOne({ phone });
    if (!user) {
      return res.status(401).json({ message: 'Утасны дугаар бүртгэлгүй байна' });
    }

    const isMatch = await user.matchPassword(password);
    if (!isMatch) {
      return res.status(401).json({ message: 'Нууц үг буруу байна' });
    }

    const token = createToken(user._id);

    res.status(200).json({
      message: 'Амжилттай нэвтэрлээ',
      token,
      user: {
        _id: user._id,
        name: `${user.lastName} ${user.firstName}`,
        phone: user.phone,
        role: 'Зорчигч',
      },
    });
  } catch (err) {
    console.error('Login алдаа:', err);
    res.status(500).json({ message: 'Серверийн алдаа' });
  }
});

// ── POST /api/auth/forgot-password ──
// Flutter илгээх: { phone }
// Flutter хүлээх: status 200
app.post('/api/auth/forgot-password', async (req, res) => {
  try {
    const { phone } = req.body;

    if (!phone) {
      return res.status(400).json({ message: 'Утасны дугаар оруулна уу' });
    }

    const user = await User.findOne({ phone });
    if (!user) {
      return res.status(404).json({ message: 'Энэ утасны дугаараар бүртгэл олдсонгүй' });
    }

    await Otp.deleteMany({ phone, type: 'reset' });
    const code = generateOtp();
    await Otp.create({ phone, code, type: 'reset' });

    await sendSms(phone, `Нууц үг сэргээх код: ${code}. 5 минутын дотор оруулна уу.`);

    res.status(200).json({
      message: 'Код амжилттай илгээгдлээ',
      code, // Dev горимд — production дээр хасна
    });
  } catch (err) {
    console.error('Forgot password алдаа:', err);
    res.status(500).json({ message: 'Серверийн алдаа' });
  }
});

// ── POST /api/auth/verify-otp ──
// Flutter илгээх: { phone, otp }
// Flutter хүлээх: status 200
app.post('/api/auth/verify-otp', async (req, res) => {
  try {
    const { phone, otp } = req.body;

    if (!phone || !otp) {
      return res.status(400).json({ message: 'Утас болон код оруулна уу' });
    }

    const otpRecord = await Otp.findOne({
      phone,
      isUsed: false,
    }).sort({ createdAt: -1 });

    if (!otpRecord) {
      return res.status(400).json({ message: 'Код олдсонгүй. Дахин авна уу.' });
    }
    if (new Date() > otpRecord.expiresAt) {
      return res.status(400).json({ message: 'Кодны хугацаа дууссан. Дахин авна уу.' });
    }
    if (otpRecord.code !== otp) {
      return res.status(400).json({ message: 'Код буруу байна' });
    }

    otpRecord.isUsed = true;
    await otpRecord.save();

    res.status(200).json({ message: 'Код амжилттай баталгаажлаа', verified: true });
  } catch (err) {
    console.error('Verify OTP алдаа:', err);
    res.status(500).json({ message: 'Серверийн алдаа' });
  }
});

// ── POST /api/auth/reset-password ──
// Flutter илгээх: { phone, otp, newPassword }
// Flutter хүлээх: status 200
app.post('/api/auth/reset-password', async (req, res) => {
  try {
    const { phone, otp, newPassword } = req.body;

    if (!phone || !otp || !newPassword) {
      return res.status(400).json({ message: 'Утас, код, шинэ нууц үг бүгдийг оруулна уу' });
    }
    if (newPassword.length < 6) {
      return res.status(400).json({ message: 'Нууц үг 6-с дээш тэмдэгт байх ёстой' });
    }

    const otpRecord = await Otp.findOne({
      phone,
      type: 'reset',
      isUsed: false,
    }).sort({ createdAt: -1 });

    if (!otpRecord) {
      return res.status(400).json({ message: 'Код олдсонгүй' });
    }
    if (new Date() > otpRecord.expiresAt) {
      return res.status(400).json({ message: 'Кодны хугацаа дууссан' });
    }
    if (otpRecord.code !== otp) {
      return res.status(400).json({ message: 'Код буруу байна' });
    }

    otpRecord.isUsed = true;
    await otpRecord.save();

    const user = await User.findOne({ phone });
    if (!user) {
      return res.status(404).json({ message: 'Хэрэглэгч олдсонгүй' });
    }

    user.password = newPassword;
    await user.save();

    res.status(200).json({ message: 'Нууц үг амжилттай солигдлоо!' });
  } catch (err) {
    console.error('Reset password алдаа:', err);
    res.status(500).json({ message: 'Серверийн алдаа' });
  }
});

// ──────────────────────────────────────────────────────────────────────────
//  PUT /api/auth/change-phone
//  Flutter илгээх: { newPhone }
//  Header: Authorization: Bearer <token> (эсвэл token-гүй бол phone-оор хайна)
// ──────────────────────────────────────────────────────────────────────────
app.put('/api/auth/change-phone', async (req, res) => {
  try {
    const { newPhone, currentPhone, userId } = req.body;

    if (!newPhone) {
      return res.status(400).json({ message: 'Шинэ утасны дугаар оруулна уу' });
    }

    // Давхардал шалгах
    const exists = await User.findOne({ phone: newPhone });
    if (exists) {
      return res.status(400).json({ message: 'Энэ утасны дугаар өөр хэрэглэгчид бүртгэлтэй байна' });
    }

    // Token, userId, эсвэл хуучин утсаар хэрэглэгч олох
    let user;
    const authHeader = req.headers.authorization;
    if (authHeader && authHeader.startsWith('Bearer')) {
      const token = authHeader.split(' ')[1];
      try {
        const decoded = jwt.verify(token, JWT_SECRET);
        user = await User.findById(decoded.id);
      } catch (_) {}
    }
    if (!user && userId) {
      user = await User.findById(userId);
    }
    if (!user && currentPhone) {
      user = await User.findOne({ phone: currentPhone });
    }

    if (!user) {
      return res.status(404).json({ message: 'Хэрэглэгч олдсонгүй' });
    }

    user.phone = newPhone;
    await user.save();

    res.status(200).json({
      message: 'Утасны дугаар амжилттай солигдлоо',
      phone: newPhone,
    });
  } catch (err) {
    console.error('Change phone алдаа:', err);
    res.status(500).json({ message: 'Серверийн алдаа' });
  }
});

// ──────────────────────────────────────────────────────────────────────────
//  PUT /api/auth/change-password
//  Flutter илгээх: { currentPassword, newPassword }
//  Header: Authorization: Bearer <token> (эсвэл token-гүй бол phone-оор)
// ──────────────────────────────────────────────────────────────────────────
app.put('/api/auth/change-password', async (req, res) => {
  try {
    const { currentPassword, newPassword, phone, userId } = req.body;

    if (!currentPassword || !newPassword) {
      return res.status(400).json({ message: 'Хуучин болон шинэ нууц үгээ оруулна уу' });
    }
    if (newPassword.length < 6) {
      return res.status(400).json({ message: 'Шинэ нууц үг 6-с дээш тэмдэгт байх ёстой' });
    }

    // Token, userId, эсвэл утсаар хэрэглэгч олох
    let user;
    const authHeader = req.headers.authorization;
    if (authHeader && authHeader.startsWith('Bearer')) {
      const token = authHeader.split(' ')[1];
      try {
        const decoded = jwt.verify(token, JWT_SECRET);
        user = await User.findById(decoded.id);
      } catch (_) {}
    }
    if (!user && userId) {
      user = await User.findById(userId);
    }
    if (!user && phone) {
      user = await User.findOne({ phone });
    }

    if (!user) {
      return res.status(404).json({ message: 'Хэрэглэгч олдсонгүй' });
    }

    // Хуучин нууц үг шалгах
    const isMatch = await user.matchPassword(currentPassword);
    if (!isMatch) {
      return res.status(401).json({ message: 'Хуучин нууц үг буруу байна' });
    }

    user.password = newPassword;
    await user.save();

    res.status(200).json({ message: 'Нууц үг амжилттай солигдлоо' });
  } catch (err) {
    console.error('Change password алдаа:', err);
    res.status(500).json({ message: 'Серверийн алдаа' });
  }
});

// ──────────────────────────────────────────────────────────────────────────
//  POST /api/drivers — Жолооч бүртгэх (Админ эсвэл тест зориулалтаар)
// ──────────────────────────────────────────────────────────────────────────
app.post('/api/drivers', async (req, res) => {
  try {
    const { lastName, firstName, phone, password, driverLicense, companyCode,
            companyName, busRoute, busNumber } = req.body;

    if (!lastName || !firstName || !phone || !password || !driverLicense || !companyCode) {
      return res.status(400).json({ message: 'Бүх талбарыг бөглөнө үү' });
    }

    const exists = await Driver.findOne({ phone });
    if (exists) {
      return res.status(400).json({ message: 'Энэ утасны дугаар бүртгэлтэй байна' });
    }

    const driver = await Driver.create({
      lastName, firstName, phone, password,
      driverLicense, companyCode,
      companyName: companyName || '',
      busRoute: busRoute || '',
      busNumber: busNumber || '',
    });

    res.status(201).json({
      message: 'Жолооч амжилттай бүртгэгдлээ!',
      driver: {
        _id: driver._id,
        name: `${driver.lastName} ${driver.firstName}`,
        phone: driver.phone,
        driverLicense: driver.driverLicense,
        companyCode: driver.companyCode,
      },
    });
  } catch (err) {
    console.error('Driver create алдаа:', err);
    res.status(500).json({ message: 'Серверийн алдаа' });
  }
});

// ── GET /api/drivers — Бүх жолооч нарын жагсаалт ──
app.get('/api/drivers', async (req, res) => {
  try {
    const drivers = await Driver.find().select('-password').sort({ createdAt: -1 });
    res.json(drivers);
  } catch (err) {
    res.status(500).json({ message: 'Серверийн алдаа' });
  }
});

// ──────────────────────────────────────────────────────────────────────────
//  POST /api/admins — Админ үүсгэх (зөвхөн серверээс)
// ──────────────────────────────────────────────────────────────────────────
app.post('/api/admins', async (req, res) => {
  try {
    const { lastName, firstName, phone, password } = req.body;

    if (!lastName || !firstName || !phone || !password) {
      return res.status(400).json({ message: 'Бүх талбарыг бөглөнө үү' });
    }

    const exists = await Admin.findOne({ phone });
    if (exists) {
      return res.status(400).json({ message: 'Энэ утасны дугаар бүртгэлтэй байна' });
    }

    const admin = await Admin.create({ lastName, firstName, phone, password });

    res.status(201).json({
      message: 'Админ амжилттай бүртгэгдлээ!',
      admin: {
        _id: admin._id,
        name: `${admin.lastName} ${admin.firstName}`,
        phone: admin.phone,
      },
    });
  } catch (err) {
    console.error('Admin create алдаа:', err);
    res.status(500).json({ message: 'Серверийн алдаа' });
  }
});

// ═══════════════════════════════════════════════════════════════════════════
//  CHAT API
// ═══════════════════════════════════════════════════════════════════════════

// ── Chat Schema ──
const messageSchema = new mongoose.Schema({
  conversationId: { type: String, required: true },
  senderId:       { type: String, required: true },
  senderName:     { type: String, default: '' },
  text:           { type: String, default: '' },
  imageUrl:       { type: String, default: '' },
  isRead:         { type: Boolean, default: false },
  createdAt:      { type: Date, default: Date.now },
});

const Message = mongoose.model('Message', messageSchema);

const conversationSchema = new mongoose.Schema({
  participants:   { type: [String], required: true },  // [userId1, userId2]
  participantNames: { type: [String], default: [] },   // [name1, name2]
  lastMessage:    { type: String, default: '' },
  lastMessageAt:  { type: Date, default: Date.now },
  unreadCount:    { type: Object, default: {} },       // { userId: count }
}, { timestamps: true });

const Conversation = mongoose.model('Conversation', conversationSchema);

// ── GET /api/chat/users — Чатлах боломжтой хэрэглэгчид ──
app.get('/api/chat/users', async (req, res) => {
  try {
    const users = await User.find().select('lastName firstName phone').sort({ createdAt: -1 });
    const userList = users.map(u => ({
      _id: u._id,
      name: `${u.lastName} ${u.firstName}`,
      phone: u.phone,
    }));
    res.json(userList);
  } catch (err) {
    res.status(500).json({ message: 'Серверийн алдаа' });
  }
});

// ── POST /api/chat/conversations — Шинэ яриа эхлүүлэх эсвэл байгааг олох ──
app.post('/api/chat/conversations', async (req, res) => {
  try {
    const { userId1, userName1, userId2, userName2 } = req.body;

    // Аль хэдийн яриа байгаа эсэх
    let conversation = await Conversation.findOne({
      participants: { $all: [userId1, userId2] },
    });

    if (!conversation) {
      conversation = await Conversation.create({
        participants: [userId1, userId2],
        participantNames: [userName1, userName2],
      });
    }

    res.json(conversation);
  } catch (err) {
    res.status(500).json({ message: 'Серверийн алдаа' });
  }
});

// ── GET /api/chat/conversations/:userId — Хэрэглэгчийн бүх яриа ──
app.get('/api/chat/conversations/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const conversations = await Conversation.find({
      participants: userId,
    }).sort({ lastMessageAt: -1 });
    res.json(conversations);
  } catch (err) {
    res.status(500).json({ message: 'Серверийн алдаа' });
  }
});

// ── GET /api/chat/messages/:conversationId — Ярианы мессежүүд ──
app.get('/api/chat/messages/:conversationId', async (req, res) => {
  try {
    const { conversationId } = req.params;
    const messages = await Message.find({ conversationId }).sort({ createdAt: 1 });
    res.json(messages);
  } catch (err) {
    res.status(500).json({ message: 'Серверийн алдаа' });
  }
});

// ── POST /api/chat/messages — Мессеж илгээх ──
app.post('/api/chat/messages', async (req, res) => {
  try {
    const { conversationId, senderId, senderName, text, imageUrl } = req.body;

    const message = await Message.create({
      conversationId,
      senderId,
      senderName: senderName || '',
      text: text || '',
      imageUrl: imageUrl || '',
    });

    // Яриаг шинэчлэх
    await Conversation.findByIdAndUpdate(conversationId, {
      lastMessage: text || '📷 Зураг',
      lastMessageAt: new Date(),
    });

    // Нөгөө хэрэглэгчид мэдэгдэл илгээх
    try {
      const conv = await Conversation.findById(conversationId);
      if (conv) {
        const otherUserId = conv.participants.find(p => p !== senderId);
        if (otherUserId) {
          await Notification.create({
            userId: otherUserId,
            fromUser: senderId,
            fromName: senderName || '',
            type: 'chat',
            message: `${senderName || 'Хэрэглэгч'}: ${text || '📷 Зураг'}`,
            postId: conversationId,
          });
        }
      }
    } catch (_) {}

    res.status(201).json(message);
  } catch (err) {
    res.status(500).json({ message: 'Серверийн алдаа' });
  }
});

// ── PUT /api/chat/messages/read — Мессежүүдийг уншсан гэж тэмдэглэх ──
app.put('/api/chat/messages/read', async (req, res) => {
  try {
    const { conversationId, userId } = req.body;
    await Message.updateMany(
      { conversationId, senderId: { $ne: userId }, isRead: false },
      { isRead: true },
    );
    res.json({ message: 'ok' });
  } catch (err) {
    res.status(500).json({ message: 'Серверийн алдаа' });
  }
});

// ═══════════════════════════════════════════════════════════════════════════
//  NOTIFICATION API
// ═══════════════════════════════════════════════════════════════════════════

// ── GET /api/notifications/:userId ──
app.get('/api/notifications/:userId', async (req, res) => {
  try {
    const notifications = await Notification.find({ userId: req.params.userId })
      .sort({ createdAt: -1 }).limit(50);
    res.json(notifications);
  } catch (err) {
    res.status(500).json({ message: 'Серверийн алдаа' });
  }
});

// ── GET /api/notifications/:userId/unread-count ──
app.get('/api/notifications/:userId/unread-count', async (req, res) => {
  try {
    const count = await Notification.countDocuments({
      userId: req.params.userId, isRead: false,
    });
    res.json({ count });
  } catch (err) {
    res.status(500).json({ message: 'Серверийн алдаа' });
  }
});

// ── PUT /api/notifications/:userId/read-all ──
app.put('/api/notifications/:userId/read-all', async (req, res) => {
  try {
    await Notification.updateMany(
      { userId: req.params.userId, isRead: false }, { isRead: true },
    );
    res.json({ message: 'ok' });
  } catch (err) {
    res.status(500).json({ message: 'Серверийн алдаа' });
  }
});

// ═══════════════════════════════════════════════════════════════════════════
//  SERVER START
// ═══════════════════════════════════════════════════════════════════════════
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log('Server running: http://localhost:' + PORT);
  console.log('');
  console.log('Хуучин endpoints (өөрчлөлтгүй):');
  console.log('  GET/POST/PUT/DELETE  /api/routes');
  console.log('  GET/DELETE           /api/feedback');
  console.log('');
  console.log('Шинэчлэгдсэн endpoints:');
  console.log('  POST  /api/feedback              → зураг upload + userId');
  console.log('  PUT   /api/feedback/:id/like      → likedBy давхар хамгаалалт');
  console.log('  POST  /api/feedback/:id/comment   → ШИНЭ сэтгэгдэл');
  console.log('');
  console.log('Auth endpoints:');
  console.log('  POST  /api/auth/register');
  console.log('  POST  /api/auth/login');
  console.log('  POST  /api/auth/forgot-password');
  console.log('  POST  /api/auth/verify-otp');
  console.log('  POST  /api/auth/reset-password');
  console.log('  PUT   /api/auth/change-phone');
  console.log('  PUT   /api/auth/change-password');
});