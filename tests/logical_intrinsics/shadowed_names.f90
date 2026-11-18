program p
implicit none
print *,all(2),any(3),count(4),merge(5),dble(6)
contains
integer function all(x)
integer,intent(in)::x
all=x+1
end function
integer function any(x)
integer,intent(in)::x
any=x+1
end function
integer function count(x)
integer,intent(in)::x
count=x+1
end function
integer function merge(x)
integer,intent(in)::x
merge=x+1
end function
integer function dble(x)
integer,intent(in)::x
dble=x+1
end function
end program
