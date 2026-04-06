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
  userName:     { type: String, default: 'Зочин' },
  userId:       { type: String, default: '' },          // ШИНЭ
  likes:        { type: Number, default: 0 },
  likedBy:      { type: [String], default: [] },        // ШИНЭ — Flutter дээр шалгадаг
  comments:     { type: Number, default: 0 },
  commentsList: { type: [commentSchema], default: [] }, // ШИНЭ
  mediaUrls:    { type: [String], default: [] },        // ШИНЭ
  image:        { type: String, default: '' },          // Хуучин field хэвээр
  createdAt:    { type: Date, default: Date.now },
});

const Feedback = mongoose.model('Feedback', feedbackSchema);

// ── ШИНЭ: User Schema ──
const userSchema = new mongoose.Schema({
  lastName:        { type: String, required: true, trim: true },
  firstName:       { type: String, required: true, trim: true },
  phone:           { type: String, required: true, unique: true, trim: true },
  password:        { type: String, required: true, minlength: 6 },
  role:            { type: String, enum: ['Зорчигч', 'Жолооч', 'Админ'], default: 'Зорчигч' },
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

// ── GET /api/feedback  |  GET /api/feedback?type=гомдол ──
// Flutter уншдаг: _id, type, message, userName, busNumber, likes,
//   likedBy, comments, commentsList, createdAt, mediaUrls
app.get('/api/feedback', async (req, res) => {
  try {
    const filter = {};
    if (req.query.type) {
      filter.type = req.query.type;
    }
    const feedbacks = await Feedback.find(filter).sort({ createdAt: -1 });
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
      userName: userName || 'Зочин',
      userId: userId || '',
      mediaUrls,
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
    res.json(feedback);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// ── DELETE /api/feedback/:id (ХУУЧНААР) ──
app.delete('/api/feedback/:id', async (req, res) => {
  try {
    await Feedback.findByIdAndDelete(req.params.id);
    res.json({ message: 'Deleted' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

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
// Flutter илгээх: { phone, password, role }
// Flutter хүлээх: status 200, { user: { _id, name, phone } }
app.post('/api/auth/login', async (req, res) => {
  try {
    const { phone, password } = req.body;

    if (!phone || !password) {
      return res.status(400).json({ message: 'Утас болон нууц үгээ оруулна уу' });
    }

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
        role: user.role,
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
  console.log('Шинэ Auth endpoints:');
  console.log('  POST  /api/auth/register');
  console.log('  POST  /api/auth/login');
  console.log('  POST  /api/auth/forgot-password');
  console.log('  POST  /api/auth/verify-otp');
  console.log('  POST  /api/auth/reset-password');
});