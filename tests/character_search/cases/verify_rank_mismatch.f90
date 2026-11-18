program p
implicit none
print *, verify(['ab','ba'],reshape(['a','b'],[1,2]))
end program
