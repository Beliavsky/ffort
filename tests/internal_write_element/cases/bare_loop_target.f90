program main
implicit none
character(2)::a(3)
integer::i
i=1
do
if(i>3)exit
write(a(i),'(i2.2)')i+4
i=i+1
end do
print '(a)',a
end program
