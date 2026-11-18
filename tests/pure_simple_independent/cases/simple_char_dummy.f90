program purity_test
implicit none

! simple subroutine bogus(xx)
call accept("simple subroutine adjust(xx)")
print *,42
contains
simple subroutine accept(txt)
character(len=*),intent(in)::txt
end subroutine

end program
