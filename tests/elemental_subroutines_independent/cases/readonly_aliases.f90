program elemental_actions
implicit none
integer::aa(3),bb(3)
aa(1)=2
aa(2)=4
aa(3)=6
call work(aa,aa,bb)
print *,bb
contains
elemental subroutine work(xx,yy,zz)
integer,intent(in)::xx,yy
integer,intent(out)::zz
zz=xx+yy
end subroutine work

end program
