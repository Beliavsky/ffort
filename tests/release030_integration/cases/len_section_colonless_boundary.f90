! Synthetic release 0.30 composition fixture; not an extracted utility body.
program composition
implicit none
character(4) x(2)
x='test'
call inspect(x)
contains
subroutine inspect(a)
character(*),intent(in) :: a(:)
character(len=len(a(:))) text
text='test'
print *,len(text)
end subroutine
end program
