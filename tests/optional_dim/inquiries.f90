program p
implicit none
call f()
call f(2,.true.)
contains
subroutine f(x,flag)
integer,optional,intent(in)::x
logical,optional,intent(in)::flag
print *,kind(dble(x)),kind(merge(x,0,present(x)))
print *,kind(count([present(x),present(flag)],kind=8)),count([present(x),present(flag)])
if(present(x)) then
 print *,dble(x),merge(x,0,present(x)),any([present(x),present(flag)])
else
 print *,all([present(x),present(flag)]),any([present(x),present(flag)])
end if
end subroutine
end program
