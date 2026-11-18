program p
implicit none
character(2)::a(4),x(2)
a=['aa','zz','bb','ww']
x=max(a(4:1:-2),'c')
write(*,'(a)')x
end program
