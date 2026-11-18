program main
implicit none
character(5)::words(2)=['hello','world']
call use_local(words)
contains
subroutine use_local(x)
character(*),intent(in)::x(:)
character(len=len(x)+1),allocatable::y(:)
allocate(y(2)); y=x
print *,len(y),size(y)
print '(2a7)',y
end subroutine

end program
