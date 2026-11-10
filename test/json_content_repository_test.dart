import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:via_mioritica/src/repositories/json_content_repository.dart';
void main() {
  test('decodes and memoizes injected raw content', () async {
    var loads=0;
    final r=JsonContentRepository<List<String>>(cacheKey:'test',hostedUrl:'https://example.test/content.json',loadFromBundledAsset:() async => <dynamic>['fallback'],loadRaw:() async { loads++; return <dynamic>['one','two']; },decode:(raw)=>(raw as List<dynamic>).cast<String>());
    expect(await r.load(), ['one','two']); expect(await r.load(), ['one','two']); expect(loads,1);
  });
  test('shares one in-flight load', () async {
    final gate=Completer<void>(); var loads=0;
    final r=JsonContentRepository<String>(cacheKey:'test',hostedUrl:'https://example.test/content.json',loadFromBundledAsset:() async=>'fallback',loadRaw:() async { loads++; await gate.future; return 'value'; },decode:(raw)=>raw as String);
    final a=r.load(); final b=r.load(); expect(loads,1); gate.complete(); await expectLater(a,completion('value')); await expectLater(b,completion('value'));
  });
  test('retries after failure', () async {
    var loads=0;
    final r=JsonContentRepository<String>(cacheKey:'test',hostedUrl:'https://example.test/content.json',loadFromBundledAsset:() async=>'fallback',loadRaw:() async { loads++; if(loads==1) throw StateError('temporary'); return 'ok'; },decode:(raw)=>raw as String);
    await expectLater(r.load(),throwsStateError); expect(await r.load(),'ok'); expect(loads,2);
  });
  test('clearMemoryCache reloads', () async {
    var loads=0;
    final r=JsonContentRepository<int>(cacheKey:'test',hostedUrl:'https://example.test/content.json',loadFromBundledAsset:() async=>0,loadRaw:() async=>++loads,decode:(raw)=>raw as int);
    expect(await r.load(),1); r.clearMemoryCache(); expect(await r.load(),2);
  });
}

