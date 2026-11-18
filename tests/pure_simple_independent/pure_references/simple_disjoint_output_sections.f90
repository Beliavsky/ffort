program purity_test
implicit none
integer :: aa(4)
aa=0
call separate(aa(1:2),aa(3:4))
print *,aa
contains
pure subroutine separate(xx,yy)
integer,intent(out)::xx(:),yy(:)
xx=2
yy=7
end subroutine

end program
