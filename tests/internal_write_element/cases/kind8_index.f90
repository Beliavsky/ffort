program main
implicit none
character(2)::a(2)
integer(kind=8)::i
i=2_8
write(a(i),'(i2.2)')7
print '(a)',a(2)
end program
