// Create a new object, that prototypally inherits from the Error constructor.
function LockError(message) {
  this.name                     = 'LockError';
  this.message                  = message || 'LockNegotiationFailed';
}
LockError.prototype             = Object.create(Error.prototype);
LockError.prototype.constructor = LockError;

module.exports                  = LockError;
