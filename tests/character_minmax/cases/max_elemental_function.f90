program p
write(*,"(a)")f(["aa","zz"])
contains
pure elemental function f(a) result(b)
character(2),intent(in)::a
character(3)::b
b=max(a,"bbb")
end function
end program
