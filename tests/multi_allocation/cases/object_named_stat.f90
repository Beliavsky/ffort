program p
implicit none
integer,allocatable::stat(:),a(:)
allocate(stat(2),a(3))
print *,size(stat),size(a)
deallocate(stat,a)
print *,allocated(stat),allocated(a)
end program
