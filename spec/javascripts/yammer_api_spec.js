require('/assets/yammer_api.js');
require('/assets/underscore.js');

describe('YammerApi.autocomplete', function(){
  beforeEach(function(){
    window.yam = {
      request: jasmine.createSpy('yam.request')
    };
  });

  describe('.get', function(){
    it('passes the correct arguments to yam.request', function(){
      var term = 'foobar';
      var autocompleteCallback = jasmine.createSpy('autocompleteCallback');
      spyOn(YammerApi.autocomplete, 'successCallback').andReturn(autocompleteCallback);
      YammerApi.autocomplete.get(term);
      expect(yam.request).toHaveBeenCalledWith({
        url: '/api/v1/autocomplete.json',
        method: 'GET',
        data: 'prefix=' + term,
        success: autocompleteCallback
      });
    });
  });

  describe('.successCallback', function(){
    it('returns a function that passes user info to a provided function', function(){
      var autocompleteCallback = jasmine.createSpy('autocompleteCallback');
      var yammerData = {"users": [
        {"id":"1",
         "full_name":"Henry Smith",
         "messages":"14",
         "followers":"5",
         "name":"henry"},
        {"id":"2",
         "full_name":"Bob Jones",
         "messages":"14",
         "followers":"5",
         "name":"henry"}
      ]};

      var result = YammerApi.autocomplete.successCallback(autocompleteCallback)(yammerData);
      expect(autocompleteCallback).toHaveBeenCalledWith([
        { label: 'Henry Smith', value: 'Henry Smith', yammerUserId: '1' },
        { label: 'Bob Jones', value: 'Bob Jones', yammerUserId: '2' }
      ]);
    });
  });
});