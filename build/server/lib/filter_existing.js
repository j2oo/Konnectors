// Generated by CoffeeScript 1.9.3
module.exports = function(log, model, suffix, vendor) {
  return function(requiredFields, entries, body, next) {
    entries.filtered = [];
    if ((vendor == null) && entries.fetched.length > 0) {
      vendor = entries.fetched[0].vendor;
    }
    return model.all(function(err, entryObjects) {
      var entry, entryHash, i, len;
      if (err) {
        return next(err);
      }
      entryHash = {};
      for (i = 0, len = entryObjects.length; i < len; i++) {
        entry = entryObjects[i];
        if (vendor != null) {
          if (entry.vendor === vendor) {
            entryHash[entry.date.toISOString()] = entry;
          }
        } else {
          entryHash[entry.date.toISOString()] = entry;
        }
      }
      entries.filtered = entries.fetched.filter(function(entry) {
        return entryHash[entry.date.toISOString()] == null;
      });
      entries.filtered = entries.filtered.filter(function(entry) {
        return entry.vendor === vendor;
      });
      return next();
    });
  };
};
