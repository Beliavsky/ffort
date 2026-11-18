program p
implicit none
character(len=0),save :: a(2)='abc'
print *, len(a),size(a),all(a=='')
end program
