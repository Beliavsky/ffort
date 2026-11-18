program probe
use iso_fortran_env,only:int32,int64
implicit none
integer(int32)::i
integer(int64)::j
i=-1;j=-1
print '(a,b0,a,o0,a,z0,a)','[',i,'][',i,'][',i,']'
print '(a,b0,a,o0,a,z0,a)','[',j,'][',j,'][',j,']'
print '(a,b0.0,a,o0.0,a,z0.0,a)','[',0,'][',0,'][',0,']'
print '(a,b5.0,a,o5.0,a,z5.0,a)','[',0,'][',0,'][',0,']'
print '(a,b0.8,a,o0.8,a,z0.8,a)','[',1,'][',1,'][',1,']'
print '(a,b3,a,o3,a,z3,a)','[',-1,'][',-1,'][',-1,']'
i=-huge(i)-1;j=-huge(j)-1
print '(b32.32,1x,o0,1x,z0)',i,i,i
print '(b64.64,1x,o0,1x,z0)',j,j,j
end program
