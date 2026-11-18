program p
implicit none
character(len=3)::a(3)
a=cshift(make(),1)
if(any(a/=['b b',' cc','a  '])) error stop 1
print *, "PASS"
contains
function make() result(r)
character(len=3)::r(3)
r=['a  ','b b',' cc']
end function
end program
