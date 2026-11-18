module m
contains
integer function index(x)
integer,intent(in)::x
index=x+10
end function
integer function len_trim(x)
integer,intent(in)::x
len_trim=x+20
end function
integer function adjustl(x) result(v)
integer,intent(in)::x
v=x+30
end function
integer function adjustr(x) result(v)
integer,intent(in)::x
v=x+40
end function
end module
program p
use m
print *,index(1),len_trim(2),adjustl(3),adjustr(4)
print *,index(x=5),len_trim(x=6),adjustl(x=7),adjustr(x=8)
end program
