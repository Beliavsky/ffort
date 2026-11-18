program elemental_actions
implicit none
real(8)::aa(3),bb(3)
aa=0.5d0
call work(aa,2.0d0,bb)
print *,aa,bb
contains
elemental subroutine work(xx,yy,zz)
real(8),intent(inout)::xx
real(8),intent(in)::yy
real(8),intent(out)::zz
zz=xx+yy
xx=xx*yy
end subroutine work

end program
