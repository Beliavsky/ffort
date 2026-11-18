program p
implicit none
integer::x
call opt(3,x)
print *,x
call opt(3,x,10)
print *,x
contains
recursive subroutine opt(n,answer,bonus)
integer,intent(in)::n
integer,intent(out)::answer
integer,intent(in),optional::bonus
integer::v
if(n==0) then
v=0
if(present(bonus)) v=bonus
else
call opt(n-1,v,bonus)
end if
answer=v+n
end subroutine
end program
