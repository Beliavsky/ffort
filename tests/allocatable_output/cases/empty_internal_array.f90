program combined
implicit none
integer,allocatable::a(:)
character(16)::b
allocate(a(0))
write(b,'(a,3i4)')'empty',a
print '(a)',b
end program
