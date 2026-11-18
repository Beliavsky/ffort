program p
implicit none
character(0)::a(0,2,3)
character::z(2)
z='a'
print '(a)',z//new_line(a=a)
end program
