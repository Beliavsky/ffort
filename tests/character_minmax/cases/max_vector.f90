program p
implicit none
character::a(2)
character(2)::b(2)
a=['A','Z']
b=['BB','Y ']
write(*,'(a)')max(a,b),max('c',['aa','bb'])
end program
