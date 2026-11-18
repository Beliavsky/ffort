program elemental_actions
implicit none
logical::aa(3),bb(3)
aa=.true.
call invert(aa,bb)
print *,aa,bb
contains
elemental subroutine invert(xx,yy)
logical,intent(inout)::xx
logical,intent(out)::yy
yy=.not.xx
xx=yy
end subroutine invert

end program
