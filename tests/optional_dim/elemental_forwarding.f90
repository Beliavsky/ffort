program p
implicit none
call use_counts()
call use_counts(3)
contains
subroutine use_counts(b)
integer,optional,intent(in)::b
print *,count(shift([1,2,3],b)>2),all(shift([1,2,3],b)>0)
print *,dble(shift([1,2,3],b))
end subroutine
pure elemental integer function shift(a,b)
integer,intent(in)::a
integer,optional,intent(in)::b
if(present(b)) then
 shift=merge(a+b,a,a>0)
else
 shift=a
end if
end function
end program
