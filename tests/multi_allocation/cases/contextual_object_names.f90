program p
implicit none
integer,allocatable::stat(:),errmsg(:),source(:),mold(:)
integer::s
allocate(stat(2),errmsg(3),source(4),mold(5),stat=s)
print *,s,size(stat),size(errmsg),size(source),size(mold)
deallocate(stat,errmsg,source,mold,stat=s)
print *,s,allocated(stat),allocated(errmsg),allocated(source),allocated(mold)
end program
