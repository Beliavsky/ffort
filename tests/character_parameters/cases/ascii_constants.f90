implicit none
character(*),parameter::a=achar(65),b=char(90,kind=1),c=achar(i=97_8,kind=1_8)
print '(a)',a,b,c
print *,kind(a),a=="A"
end
