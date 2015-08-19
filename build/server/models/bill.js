// Generated by CoffeeScript 1.9.3
var Bill, cozydb;

cozydb = require('cozydb');

module.exports = Bill = cozydb.getModel('Bill', {
  type: String,
  date: Date,
  vendor: String,
  amount: Number,
  plan: String,
  pdfurl: String,
  binaryId: String,
  fileId: String
});

Bill.all = function(callback) {
  return Bill.request('byDate', callback);
};
