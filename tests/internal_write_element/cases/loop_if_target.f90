program main
implicit none
character(2)::a(2)
integer::i
do i=1,2
if(i>0)then
write(a(i),'(i2.2)')i+4
end if
end do
print '(a)',a
end program
