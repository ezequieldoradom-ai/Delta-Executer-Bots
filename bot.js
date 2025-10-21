
const { Client, GatewayIntentBits, ActionRowBuilder, ButtonBuilder, ButtonStyle, EmbedBuilder } = require('discord.js');
const express = require('express');

const client = new Client({ intents: [GatewayIntentBits.Guilds, GatewayIntentBits.GuildMessages] });

const token = process.env.TOKEN;

// READY
client.once('ready', () => {
  console.log(`Logged in as ${client.user.tag}`);
});

// PANEL CON BOTONES
client.on('messageCreate', async message => {
  if (message.content === '!panel') {
    const row = new ActionRowBuilder()
      .addComponents(
        new ButtonBuilder().setCustomId('version').setLabel('Version').setStyle(ButtonStyle.Primary),
        new ButtonBuilder().setCustomId('status').setLabel('Status').setStyle(ButtonStyle.Primary),
        new ButtonBuilder().setCustomId('report').setLabel('Report').setStyle(ButtonStyle.Danger),
        new ButtonBuilder().setCustomId('ios').setLabel('iOS').setStyle(ButtonStyle.Success),
        new ButtonBuilder().setCustomId('android').setLabel('Android').setStyle(ButtonStyle.Success),
        new ButtonBuilder().setCustomId('tutorial').setLabel('Tutorial').setStyle(ButtonStyle.Secondary),
      );
    await message.channel.send({ content: '📌 **Delta Executer Support Panel**', components: [row] });
  }
});

// BOTONES
client.on('interactionCreate', async interaction => {
  if (!interaction.isButton()) return;

  const staffChannel = interaction.guild.channels.cache.find(c => c.name === 'staff-errors');
  let embed;

  switch(interaction.customId) {
    case 'version':
      embed = new EmbedBuilder()
        .setTitle('🛠 Delta Executer - Version Info')
        .setDescription('```css\n[Version X (10.23) “Delta-2.694.977.ipa"]\n```\n```css\n[Changelog]\n```\n```md\n+ Updated to 2.694.977\n+ Still Undetected\n+ Improved Stability\n+ Improved Performance\n+ Improved `getrenv` further\n+ Fixed a very specific crash on `hookfunction`\n+ Bug Fixes\n```')
        .setColor(0x00AE86);
      await interaction.reply({ embeds: [embed], ephemeral: true });
      break;

    case 'status':
      embed = new EmbedBuilder()
        .setTitle('⚙️ Delta Executer Status')
        .setDescription('• Main server: ONLINE ✅')
        .setColor(0x00AE86);
      await interaction.reply({ embeds: [embed], ephemeral: true });
      break;

    case 'report':
      await interaction.reply({ content: 'Please type your error description:', ephemeral: true });
      const filter = m => m.author.id === interaction.user.id;
      const collector = interaction.channel.createMessageCollector({ filter, time: 60000, max: 1 });

      collector.on('collect', async m => {
        if (staffChannel) {
          const reportEmbed = new EmbedBuilder()
            .setTitle('📝 New Error Report')
            .addFields(
              { name: 'User', value: `${interaction.user.tag} (${interaction.user.id})` },
              { name: 'Error', value: m.content },
              { name: 'Date', value: new Date().toLocaleString() }
            )
            .setColor(0xFF0000);
          staffChannel.send({ embeds: [reportEmbed] });
        }
        await interaction.followUp({ content: '✅ Your report has been sent to the staff!', ephemeral: true });
        m.delete();
      });
      break;

    case 'ios':
      embed = new EmbedBuilder()
        .setTitle('📱 Delta Executer iOS')
        .setDescription('[Click here to download for iOS](https://delta-executor.com/ios/)')
        .setColor(0x00AE86);
      await interaction.reply({ embeds: [embed], ephemeral: true });
      break;

    case 'android':
      embed = new EmbedBuilder()
        .setTitle('🤖 Delta Executer Android')
        .setDescription('[Click here to download for Android](https://delta-executor.com/)')
        .setColor(0x00AE86);
      await interaction.reply({ embeds: [embed], ephemeral: true });
      break;

    case 'tutorial':
      embed = new EmbedBuilder()
        .setTitle('🎬 Delta Executer Tutorial')
        .setDescription('[Watch the tutorial video here](https://youtu.be/2D4MtbvjbQQ?si=ARQbA4zaiOZT-xp7)')
        .setColor(0x00AE86);
      await interaction.reply({ embeds: [embed], ephemeral: true });
      break;
  }
});

// MINI SERVIDOR PARA PING
const app = express();
app.get("/", (req, res) => res.send("Bot is alive!"));
app.listen(3000, () => console.log("Server running on port 3000"));

// LOGIN
client.login(token);
