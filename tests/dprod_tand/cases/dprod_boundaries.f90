program p
implicit none

print *,dprod(huge(1.0),huge(1.0)),dprod(tiny(1.0),tiny(1.0))
print *,dprod(1.40129846e-45,1.40129846e-45)
end program
