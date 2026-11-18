program main
implicit none
real::a(3)=[0.0,1.25,-10.5]
real(8)::b(3)=[0.0_8,1.25_8,-10.5_8]
print '(3e14.5)',a
print '(2e14.5)',b

end program
