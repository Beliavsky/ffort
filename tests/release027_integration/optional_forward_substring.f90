module m
contains
function replace(s,opt) result(yy)
character(*),intent(in)::s
character(*),intent(in),optional::opt
character(len(s))::yy
yy=s
if(present(opt)) yy(2:len(s)-1)=adjustl(opt)
end function
function forward(s,opt) result(yy)
character(*),intent(in)::s
character(*),intent(in),optional::opt
character(len(s))::yy
yy=replace(s,opt)
end function
end module
program p
use m
implicit none
print '(a)',forward('123456'),forward('123456',' ab')
end program
