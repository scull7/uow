
var PRIORITY_MAP  = {
  low:        -10,
  normal:     0,
  medium:     -5,
  high:       -10,
  critical:   -15
};

module.exports    = {
  MAP:            PRIORITY_MAP,

  LOW:            PRIORITY_MAP.low,
  NORMAL:         PRIORITY_MAP.normal,
  MEDIUM:         PRIORITY_MAP.medium,
  HIGH:           PRIORITY_MAP.high,
  CRITICAL:       PRIORITY_MAP.critical
};
