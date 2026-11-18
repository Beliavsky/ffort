program elemental_actions
implicit none
integer::aa(3),bb(3),n
aa=1
n=2
call act(aa,bb(1:n))
contains
impure elemental subroutine act(src,dst)
integer,intent(in)::src
integer,intent(out)::dst
print *,src
dst=src
end subroutine act

end program
