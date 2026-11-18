module m
contains
integer function pos(b) result(v)
logical,optional,intent(in)::b
v=index('aba','a',back=b)
end function
integer(8) function pos8(b) result(v)
logical,optional,intent(in)::b
v=index(kind=8,back=b,substring='a',string='aba')
end function
end module
program p
use m
print *,pos(),pos(.true.),pos8(.true.),pos8()
print *,index('aba','a',.true.),pos(.false.),pos8(.true.)
end program
