program main
implicit none
character(2)::a(3)
integer::i
do i=1,3
write(a(i),'(i2.2)')i+4
end do
print '(a)',a
end program
