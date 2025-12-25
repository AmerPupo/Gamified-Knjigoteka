using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Knjigoteka.Services.Migrations
{
    /// <inheritdoc />
    public partial class reviewChange : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Comment",
                table: "Reviews");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "Comment",
                table: "Reviews",
                type: "nvarchar(100)",
                maxLength: 100,
                nullable: true);
        }
    }
}
