program p
implicit none
character(2)::a(2)
a=min(['Z','A'],['YY','B '])
print '(*(a))','[',a(1),'][',a(2),']'
end program
