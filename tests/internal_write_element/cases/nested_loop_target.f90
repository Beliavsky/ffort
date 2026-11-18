program main
implicit none
character(2)::a(2,2)
integer::i,j
do j=1,2
do i=1,2
write(a(i,j),'(2i1)')i,j
end do
end do
print '(a)',a
end program
