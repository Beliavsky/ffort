module m
contains
integer function first(x) result(index)
integer,intent(in)::x
index=x+1
end function
integer function second(x) result(len_trim)
integer,intent(in)::x
len_trim=x+2
end function
integer function third(x) result(adjustl)
integer,intent(in)::x
adjustl=x+3
end function
integer function fourth(x) result(adjustr)
integer,intent(in)::x
adjustr=x+4
end function
end module
program p
use m
print *,first(1),second(1),third(1),fourth(1)
end program
