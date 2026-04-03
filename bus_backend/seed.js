// Туршилтын дата оруулах скрипт
// node seed.js

const mongoose = require('mongoose');

mongoose.connect('mongodb://localhost:27017/bus_db')
  .then(() => console.log('Холбогдлоо'));

const Route = mongoose.model('Route', new mongoose.Schema({
  name: String,
  full: String,
  phone: String,
}));

const sampleRoutes = [
  { name: '11', full: 'Баянзүрх - Төв шуудан', phone: '70110011' },
  { name: '22', full: 'Яармаг - Их дэлгүүр', phone: '70220022' },
  { name: '33', full: 'Сонгинохайрхан - Нийслэлийн эмнэлэг', phone: '70330033' },
  { name: '45', full: 'Хан-Уул - Нарантуул', phone: '70450045' },
  { name: '57', full: 'Чингэлтэй - Дэлхийн II дайны музей', phone: '70570057' },
];

Route.insertMany(sampleRoutes)
  .then(() => {
    console.log('Дата орлоо!');
    mongoose.disconnect();
  });
