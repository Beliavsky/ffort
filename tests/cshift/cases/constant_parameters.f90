program p
implicit none
integer,parameter::a(3)=[1,2,3]
integer,parameter::b(3)=cshift(a,-1)
character(len=2),parameter::c(3)=cshift(["ab","cd","ef"],1)
if(any(b/=[3,1,2])) error stop 1
if(any(c/=['cd','ef','ab'])) error stop 2
print *, "PASS"
end program
