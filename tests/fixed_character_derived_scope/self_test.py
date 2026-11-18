from run_tests import compare
checks=0
def test(v):
 global checks
 assert v;checks+=1
for value in ['','\n','x\n','x \n','\n\n','x\n\ny\n','x\ny']:
 test(compare(value,value));test(not compare(value,value+'\n'));test(not compare(value+' ',value))
test(compare(' 0001 +2\n','1 2\n',[0]))
for x in ['1.0 2\n','1e0 2\n','1 3\n','1 2','1 2\n\n','1 2 3\n','nan 2\n']:
 test(not compare(x,'1 2\n',[0]))
test(not compare('9007199254740993\n','9007199254740992\n',[0]))
print(checks,'checks pass')
