program elemental_actions
implicit none
integer::aa,bb
aa=3
call work(aa,4,bb)
print *,aa,bb
contains
elemental subroutine work(xx,yy,zz)
integer,intent(inout)::xx
integer,intent(in)::yy
integer,intent(out)::zz
zz=xx+yy
xx=xx*yy
end subroutine work

end program
