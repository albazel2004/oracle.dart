import 'dart:io';
import 'package:oracle/oracle.dart' as oracle;
import 'package:test/test.dart';
import 'package:collection/equality.dart';

main() {
  var username;
  var password;
  var connString;
  var env;
  var con;

  setUp((){
    username = Platform.environment['DB_USERNAME'];
    password = Platform.environment['DB_PASSWORD'];
    connString = Platform.environment['DB_CONN_STR'];

    env = new oracle.Environment();
    con = env.createConnection(username, password, connString);
    var stmt = con.createStatement("BEGIN EXECUTE IMMEDIATE 'DROP TABLE test_table'; EXCEPTION WHEN OTHERS THEN NULL; END;");
    stmt.execute();
    con.commit();
    stmt = con.createStatement("CREATE TABLE test_table ( test_int int, test_string varchar(255), test_date DATE, test_blob BLOB, test_clob CLOB)");
    stmt.execute();
    con.commit();
    stmt = con.createStatement("INSERT INTO test_table (test_int,test_string,test_date,test_blob, test_clob) VALUES (:b1, :b2, :b3, EMPTY_BLOB(), EMPTY_CLOB())");
    stmt.setInt(1,34);
    stmt.setString(2,"hello world");
    stmt.setDate(3,new DateTime(2012, 12, 19, 34, 35, 36));
    stmt.execute();
    con.commit();
  });
  tearDown((){
    var stmt = con.createStatement("DROP TABLE test_table");
    stmt.execute();
    con.commit();
  });
  test('test blob', () {
    List<int> bloblist = [2, 4, 6, 8, 10];
    var stmt = con.createStatement("SELECT test_blob FROM test_table FOR UPDATE");
    var results = stmt.executeQuery();
    results.next(1);
    oracle.Blob bl = results.getBlob(1);
    bl.write(5,bloblist,1);
    con.commit();
    stmt = con.createStatement("SELECT test_blob FROM test_table");
    results = stmt.executeQuery();
    results.next(1);
    var dbblob = results.getBlob(1);
    expect(dbblob.length(), equals(5));
    var rlist = dbblob.read(5,1);
    expect(rlist, equals(bloblist));
  });
  test('test clob', (){
    var stmt = con.createStatement("SELECT test_clob FROM test_table FOR UPDATE");
    var results = stmt.executeQuery();
    results.next(1);
    oracle.Clob cl = results.getClob(1);
    cl.write(10,"teststring",1);
    con.commit();
    stmt = con.createStatement("SELECT test_clob FROM test_table");
    results = stmt.executeQuery();
    results.next(1);
    var dbblob = results.getClob(1);
    expect(dbblob.length(), equals(10));
    var rlist = dbblob.read(10,1);
    expect(rlist, equals("teststring"));
  });

  test('test Blob(Connection)', () {
    new oracle.Blob(con);
  }, skip: 'Causes a segfault');

  test('test select', () {
        var stmt = con.createStatement("SELECT * FROM test_table");
        var results = stmt.executeQuery();
        results.next(1);
        expect(results.getNum(1), equals(34));
        expect(results.getString(2), equals("hello world"));
        expect(results.getDate(3).toString(), equals(new DateTime(2012, 12, 19, 34, 35, 36).toString()));
  });
  test('test status', () {
        var stmt = con.createStatement("SELECT test_int from test_table");
        expect(stmt.status(), equals(oracle.StatementStatus.PREPARED));
        var res = stmt.execute();
        expect(res, equals(oracle.StatementStatus.RESULT_SET_AVAILABLE));
        res = stmt.status();
        expect(res, equals(oracle.StatementStatus.RESULT_SET_AVAILABLE));
        stmt = con.createStatement("UPDATE test_table set test_int=2");
        res = stmt.execute();
        expect(res, equals(oracle.StatementStatus.UPDATE_COUNT_AVAILABLE));
        res = stmt.status();
        expect(res, equals(oracle.StatementStatus.UPDATE_COUNT_AVAILABLE));
  });
  test('test update', () {
    var sql = 'UPDATE test_table set test_int=:bind';
    var sql2 = 'SELECT * FROM test_table';
    var stmt = con.createStatement(sql);
    var stmt2 = con.createStatement(sql2);
    stmt.setInt(1, 2);
    stmt.execute();
    con.commit();
    var results = stmt2.executeQuery();
    results.next(1);
    expect(results.getNum(1), equals(2));
    stmt.setInt(1, 1);
    stmt.execute();
    con.commit();
    results = stmt2.executeQuery();
    results.next(1);
    expect(results.getNum(1), equals(1));
  });
  test('test insert nulls', (){
    var sql = 'UPDATE test_table set test_int=:b1, test_string=:b2, test_date=:b3, test_blob=null, test_clob=null';
    var sql2 = 'SELECT * FROM test_table';
    var stmt = con.createStatement(sql);
    var stmt2 = con.createStatement(sql2);
    stmt.setInt(1, null);
    stmt.setString(2, null);
    stmt.setDate(3, null);
    stmt.execute();
    con.commit();
    var results = stmt2.executeQuery();
    results.next(1);
    expect(results.getNum(1), equals(null));
    expect(results.getString(2), equals(null));
    expect(results.getDate(3), equals(null));
    expect(results.getBlob(4), equals(null));
    expect(results.getClob(5), equals(null));
  });
  test('test get', (){
        var stmt = con.createStatement("SELECT * FROM test_table");
        var results = stmt.executeQuery();
        results.next(1);
        expect(results.get(1), equals(34));
        expect(results.get(2), equals("hello world"));
        expect(results.get(3).toString(), equals(new DateTime(2012, 12, 19, 34, 35, 36).toString()));
  });
}
