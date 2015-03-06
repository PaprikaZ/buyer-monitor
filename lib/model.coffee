mongoose = require('mongoose')
config = require('./config.js')

availableSites = [ 'www.amazon.com', 'www.amazon.cn', 'www.amazon.co.jp', 'www.jd.com' ]
availableCurrencies = ['CNY', 'EUR', 'USD', 'JPY', 'AUD']
availableVerdictFields = ['price', 'discount', 'review', 'instore', 'benefits']
availableVerdictMethods = ['above', 'under', 'equal', 'match']
recordSchema = new mongoose.Schema({
  id: {
    type: String
    required: true
    trim: true
  }
  site: {
    type: String
    required: true
    enum: availableSites
  }
  url: {
    type: String
    required: true
    trim: true
  }
  created: {
    type: Date
    required: true
  }
  name: {
    type: String
    required: true
    trim: true
  }
  price: {
    type: Number
    required: true
    min: 0
  }
  fullPrice: {
    type: Number
    default: 0
    required: false
    min: 0
  }
  currency: {
    type: String
    required: true
    enum: availableCurrencies
    uppercase: true
  }
  instore: {
    type: Boolean
    required: true
  }
  review: {
    type: Number
    default: -1
    require: true
    max: 10
    min: -1
  }
  benefits: {
    type: [{
      type: String
      required: true
      trim: true
    }]
    default: ["none"]
    required: false
  }
  comments: {
    type: String
    required: false
    default: ''
  }
  verdict: {
    type: Boolean
    required: true
    default: false
  }
}, config.mongoSchemaOptions)

FieldVerdictSchema = new mongoose.Schema({
  field: {
    type: String
    required: true
    enum: availableVerdictFields
  }
  verdict: {
    type: String
    required: true
    enum: availableVerdictMethods
  }
  target: {
    type: String
    required: true
  }
}, config.mongoSchemaOptions)

verdictSchema = new mongoose.Schema({
  id: {
    type: String
    required: true
    trim: true
  }
  site: {
    type: String
    required: true
    enum: availableSites
  }
  fields: [FieldVerdictSchema]
}, config.mongoSchemaOptions)

module.exports = exports = {
  Record: mongoose.model('Record', recordSchema)
  Verdict: mongoose.model('Verdict', verdictSchema)
}
